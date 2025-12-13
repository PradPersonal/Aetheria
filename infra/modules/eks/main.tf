# EKS Cluster using the community terraform-aws-eks module
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  # VPC Configuration
  vpc_id                          = var.vpc_id
  subnet_ids                      = var.private_subnets
  control_plane_subnet_ids        = var.private_subnets
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Security
  cluster_endpoint_public_access_cidrs = var.allowed_cidr_blocks

  # Enable EKS managed add-ons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    general = {
      name            = "general"
      use_name_prefix = true

      instance_types = var.node_group_instance_types
      capacity_type  = var.enable_spot_instances ? "SPOT" : "ON_DEMAND"

      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size

      # Launch template configuration
      create_launch_template = true
      launch_template_name   = "${var.name}-node-group"
      
      # EBS optimized instances
      ebs_optimized = true
      
      # Instance metadata service configuration
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "enabled"
      }

      # User data for nodes
      pre_bootstrap_user_data = <<-EOT
        #!/bin/bash
        /etc/eks/bootstrap.sh ${var.cluster_name} --apiserver-endpoint '${module.eks.cluster_endpoint}' --b64-cluster-ca '${module.eks.cluster_certificate_authority_data}'
        
        # Install SSM agent for debugging
        yum install -y amazon-ssm-agent
        systemctl enable amazon-ssm-agent
        systemctl start amazon-ssm-agent
      EOT

      # Disk configuration
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      # IAM role for nodes
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      tags = var.tags
    }

    # Spot instances node group for cost optimization
    spot = {
      name            = "spot"
      use_name_prefix = true

      instance_types = ["t3.medium", "t3.large", "t3a.medium", "t3a.large"]
      capacity_type  = "SPOT"

      min_size     = 0
      max_size     = 10
      desired_size = var.enable_spot_instances ? 2 : 0

      # Taints for spot instances
      taints = {
        spot = {
          key    = "spot-instance"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }

      labels = {
        node-type = "spot"
      }

      tags = merge(var.tags, {
        "k8s.io/cluster-autoscaler/enabled" = "true"
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      })
    }
  }

  # Enable IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Cluster logging
  cluster_enabled_log_types = var.enable_eks_logging ? [
    "api",
    "audit", 
    "authenticator",
    "controllerManager",
    "scheduler"
  ] : []

  cloudwatch_log_group_retention_in_days = 14

  # Cluster security group additional rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  # Node security group additional rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    
    # Allow nodes to communicate with ALB
    ingress_cluster_to_node_all_traffic = {
      description                   = "Cluster API to Nodegroup all traffic"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  tags = var.tags
}

# IRSA for AWS Load Balancer Controller
module "load_balancer_controller_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.name}-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:${var.service_accounts.aws_load_balancer_controller}"]
    }
  }

  tags = var.tags
}

# IRSA for Cluster Autoscaler
module "cluster_autoscaler_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.name}-cluster-autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:${var.service_accounts.cluster_autoscaler}"]
    }
  }

  tags = var.tags
}

# IRSA for EBS CSI Driver
module "ebs_csi_driver_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.name}-ebs-csi-driver"

  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:${var.service_accounts.ebs_csi_driver}"]
    }
  }

  tags = var.tags
}

# IRSA for External DNS
module "external_dns_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.name}-external-dns"

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [var.route53_zone_arn]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:${var.service_accounts.external_dns}"]
    }
  }

  tags = var.tags
}
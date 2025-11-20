# Main Terraform configuration for Aetheria AWS infrastructure
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket = "aetheria-terraform-state"
  #   key    = "infrastructure/terraform.tfstate"
  #   region = "ca-central-1"
  #   
  #   dynamodb_table = "aetheria-terraform-locks"
  #   encrypt        = true
  # }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Provider for ACM certificates (must be us-east-1 for CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = local.common_tags
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  name                  = local.name
  vpc_cidr             = local.vpc_cidr
  azs                  = local.azs
  private_subnets      = local.private_subnets
  public_subnets       = local.public_subnets
  database_subnets     = local.database_subnets
  single_nat_gateway   = var.environment == "dev" ? true : false
  enable_vpc_flow_logs = var.enable_vpc_flow_logs
  cluster_name         = local.cluster_name
  tags                 = local.common_tags
}

# Route53 and ACM Module
module "route53" {
  source = "./modules/route53"

  name                                 = local.name
  domain_name                         = var.domain_name
  api_domain_name                     = var.api_domain_name
  cdn_domain_name                     = var.cdn_domain_name
  aws_region                          = var.aws_region
  alb_subject_alternative_names       = ["*.${var.domain_name}", var.api_domain_name]
  cloudfront_subject_alternative_names = ["*.${var.cdn_domain_name}"]
  alb_dns_name                        = module.alb.alb_dns_name
  alb_zone_id                         = module.alb.alb_zone_id
  cloudfront_domain_name              = module.cloudfront.cloudfront_domain_name
  cloudfront_hosted_zone_id           = module.cloudfront.cloudfront_hosted_zone_id
  enable_health_check                 = var.environment == "prod"
  tags                                = local.common_tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  name                       = local.name
  cluster_name              = local.cluster_name
  kubernetes_version        = var.kubernetes_version
  vpc_id                    = module.vpc.vpc_id
  private_subnets           = module.vpc.private_subnets
  allowed_cidr_blocks       = var.allowed_cidr_blocks
  node_group_instance_types = var.node_group_instance_types
  node_group_min_size       = var.node_group_min_size
  node_group_max_size       = var.node_group_max_size
  node_group_desired_size   = var.node_group_desired_size
  enable_spot_instances     = var.enable_spot_instances
  enable_eks_logging        = var.enable_eks_logging
  route53_zone_arn          = module.route53.route53_zone_arn
  service_accounts          = local.service_accounts
  tags                      = local.common_tags
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  name                      = local.name
  ecr_repositories          = local.ecr_repositories
  cluster_iam_role_arn      = module.eks.cluster_arn
  node_group_iam_role_name  = "eks-node-group-general" # This will need to be extracted from EKS module
  tags                      = local.common_tags
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  name                         = local.name
  media_bucket_name           = local.media_bucket_name
  logs_bucket_name            = local.logs_bucket_name
  media_bucket_lifecycle_days = var.media_bucket_lifecycle_days
  logs_bucket_lifecycle_days  = var.logs_bucket_lifecycle_days
  allowed_origins             = ["https://${var.domain_name}", "https://${var.cdn_domain_name}"]
  oidc_provider_arn           = module.eks.oidc_provider_arn
  service_accounts            = ["aetheria:streaming-service", "aetheria:media-processor"]
  tags                        = local.common_tags
}

# WAF Module
module "waf" {
  source = "./modules/waf"

  name                    = local.name
  enable_cloudfront_waf   = var.enable_waf
  enable_alb_waf         = var.enable_waf
  enable_rate_limiting    = true
  rate_limit_requests     = var.environment == "prod" ? 5000 : 2000
  blocked_countries       = var.blocked_countries
  enable_waf_logging      = var.enable_waf_logging
  cloudwatch_log_group_arn = "" # Add if WAF logging is needed
  tags                    = local.common_tags
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  name                       = local.name
  vpc_id                     = module.vpc.vpc_id
  public_subnets             = module.vpc.public_subnets
  acm_certificate_arn        = module.route53.alb_certificate_arn
  enable_deletion_protection = var.environment == "prod"
  enable_access_logs         = var.enable_alb_logging
  logs_bucket_name           = module.s3.logs_bucket_id
  health_check_path          = "/health"
  api_hostnames              = [var.api_domain_name]
  waf_web_acl_arn           = module.waf.alb_web_acl_arn
  tags                       = local.common_tags
}

# CloudFront Module
module "cloudfront" {
  source = "./modules/cloudfront"

  name                            = local.name
  s3_bucket_name                 = module.s3.media_bucket_id
  s3_bucket_regional_domain_name = module.s3.media_bucket_regional_domain_name
  aliases                        = [var.cdn_domain_name]
  acm_certificate_arn            = module.route53.cloudfront_certificate_arn
  price_class                    = var.cloudfront_price_class
  enable_logging                 = var.enable_cloudfront_logging
  logs_bucket_domain_name        = module.s3.logs_bucket_id
  enable_signed_urls             = var.enable_signed_urls
  geo_restriction_type           = "none"
  geo_restriction_locations      = []
  waf_web_acl_arn               = module.waf.cloudfront_web_acl_arn
  create_security_headers_function = true
  tags                           = local.common_tags
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# Helm provider configuration
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}
variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be created"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the cluster API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_group_instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_min_size" {
  description = "Minimum size of node group"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum size of node group"
  type        = number
  default     = 5
}

variable "node_group_desired_size" {
  description = "Desired size of node group"
  type        = number
  default     = 2
}

variable "enable_spot_instances" {
  description = "Enable spot instances for cost optimization"
  type        = bool
  default     = false
}

variable "enable_eks_logging" {
  description = "Enable EKS control plane logging"
  type        = bool
  default     = false
}

variable "route53_zone_arn" {
  description = "Route53 hosted zone ARN for External DNS"
  type        = string
}

variable "service_accounts" {
  description = "Service account names for IRSA"
  type = object({
    aws_load_balancer_controller = string
    cluster_autoscaler          = string
    ebs_csi_driver             = string
    external_dns               = string
  })
  default = {
    aws_load_balancer_controller = "aws-load-balancer-controller"
    cluster_autoscaler          = "cluster-autoscaler"
    ebs_csi_driver             = "ebs-csi-controller-sa"
    external_dns               = "external-dns"
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
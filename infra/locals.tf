# Local values and common tags
locals {
  name = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }

  # VPC Configuration
  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  # Subnets
  public_subnets = [
    for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)
  ]
  
  private_subnets = [
    for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)
  ]

  database_subnets = [
    for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 20)
  ]

  # ECR Repository names
  ecr_repositories = var.services

  # S3 Bucket names (must be globally unique)
  media_bucket_name = "${local.name}-media-${random_id.bucket_suffix.hex}"
  logs_bucket_name  = "${local.name}-logs-${random_id.bucket_suffix.hex}"
  
  # Domain configuration
  domain_name     = var.domain_name
  api_domain_name = var.api_domain_name
  cdn_domain_name = var.cdn_domain_name

  # EKS Configuration
  cluster_name = "${local.name}-cluster"
  
  # Service account names for IRSA
  service_accounts = {
    aws_load_balancer_controller = "aws-load-balancer-controller"
    external_dns                = "external-dns"
    cluster_autoscaler          = "cluster-autoscaler"
    ebs_csi_driver             = "ebs-csi-controller"
  }
}

# Data sources
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Random ID for unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
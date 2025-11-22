# Input variables for Aetheria infrastructure

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ca-central-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "aetheria"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "aetheria.prad.com"
}

variable "api_domain_name" {
  description = "API domain name"
  type        = string
  default     = "api.aetheria.prad.com"
}

variable "cdn_domain_name" {
  description = "CDN domain name for media"
  type        = string
  default     = "cdn.aetheria.prad.com"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for the region"
  type        = list(string)
  default     = ["ca-central-1a", "ca-central-1b", "ca-central-1c"]
}

# EKS Configuration
variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_group_instance_types" {
  description = "Instance types for EKS node groups"
  type        = list(string)
  default     = ["t3.medium", "t3.micro"]
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 5
}

# Application Configuration
variable "services" {
  description = "List of microservices for ECR repositories"
  type        = list(string)
  default     = [
    "aetheria-web",
    "aetheria-auth-service",
    "aetheria-streaming-service", 
    "aetheria-chat-service",
    "aetheria-core-api-service"
  ]
}

# S3 Configuration
variable "media_bucket_lifecycle_days" {
  description = "Days after which to transition media files to IA storage"
  type        = number
  default     = 30
}

variable "logs_bucket_lifecycle_days" {
  description = "Days after which to delete log files"
  type        = number
  default     = 90
}

# CloudFront Configuration
variable "cloudfront_price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_100"
  
  validation {
    condition = contains([
      "PriceClass_All",
      "PriceClass_200", 
      "PriceClass_100"
    ], var.cloudfront_price_class)
    error_message = "Price class must be one of: PriceClass_All, PriceClass_200, PriceClass_100."
  }
}

# Monitoring and Logging
variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "enable_eks_logging" {
  description = "Enable EKS control plane logging"
  type        = bool
  default     = true
}

# Security
variable "enable_waf" {
  description = "Enable WAF for production environments"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the cluster"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production
}

# Cost Management
variable "enable_spot_instances" {
  description = "Enable spot instances for cost optimization"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}
variable "blocked_countries" {
  description = "blocked countries"
  type        = list(string)
  default     = ["us-west-1"]
}
variable "enable_waf_logging" {
  description = "Enable waf logging"
  type        = bool
  default     = false
}
variable "enable_alb_logging" {
  description = "Enable alb logging"
  type        = bool
  default     = false
}
variable "enable_cloudfront_logging" {
  description = "Enable cloudfront logging"
  type        = bool
  default     = false
}
variable "enable_signed_urls" {
  description = "Enable signed logging"
  type        = bool
  default     = false
}
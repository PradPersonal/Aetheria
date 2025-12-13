# Output values for the infrastructure

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

# Route53 & ACM Outputs
output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.route53.route53_zone_id
}

output "route53_zone_name_servers" {
  description = "Route53 hosted zone name servers"
  value       = module.route53.route53_zone_name_servers
}

output "alb_certificate_arn" {
  description = "ARN of the ALB SSL certificate"
  value       = module.route53.alb_certificate_arn
}

output "cloudfront_certificate_arn" {
  description = "ARN of the CloudFront SSL certificate"
  value       = module.route53.cloudfront_certificate_arn
}

# EKS Outputs
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if enabled"
  value       = module.eks.oidc_provider_arn
}

# IRSA Role ARNs
output "load_balancer_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = module.eks.load_balancer_controller_role_arn
}

output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN for Cluster Autoscaler"
  value       = module.eks.cluster_autoscaler_role_arn
}

output "external_dns_role_arn" {
  description = "IAM role ARN for External DNS"
  value       = module.eks.external_dns_role_arn
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value       = module.ecr.ecr_repository_urls
}

output "ecr_repository_arns" {
  description = "Map of ECR repository ARNs"
  value       = module.ecr.ecr_repository_arns
}

# S3 Outputs
output "media_bucket_name" {
  description = "Name of the media S3 bucket"
  value       = module.s3.media_bucket_id
}

output "logs_bucket_name" {
  description = "Name of the logs S3 bucket"
  value       = module.s3.logs_bucket_id
}

output "s3_access_role_arn" {
  description = "IAM role ARN for S3 access via IRSA"
  value       = module.s3.s3_access_role_arn
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = module.alb.alb_zone_id
}

output "web_target_group_arn" {
  description = "ARN of the web target group"
  value       = module.alb.web_target_group_arn
}

output "api_target_group_arn" {
  description = "ARN of the API target group"
  value       = module.alb.api_target_group_arn
}

# CloudFront Outputs
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.cloudfront_domain_name
}

output "cdn_url" {
  description = "CloudFront distribution URL"
  value       = "https://${var.cdn_domain_name}"
}

# WAF Outputs
output "cloudfront_waf_arn" {
  description = "CloudFront WAF Web ACL ARN"
  value       = module.waf.cloudfront_web_acl_arn
}

output "alb_waf_arn" {
  description = "ALB WAF Web ACL ARN"
  value       = module.waf.alb_web_acl_arn
}

# Connection Information
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "application_urls" {
  description = "Application URLs"
  value = {
    main_site = "https://${var.domain_name}"
    api       = "https://${var.api_domain_name}"
    cdn       = "https://${var.cdn_domain_name}"
  }
}
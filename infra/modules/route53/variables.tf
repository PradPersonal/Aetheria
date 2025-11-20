variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "domain_name" {
  description = "Main domain name"
  type        = string
}

variable "api_domain_name" {
  description = "API domain name"
  type        = string
  default     = ""
}

variable "cdn_domain_name" {
  description = "CDN domain name"
  type        = string
}

variable "aws_region" {
  description = "AWS region for health checks"
  type        = string
}

variable "alb_subject_alternative_names" {
  description = "Subject alternative names for ALB certificate"
  type        = list(string)
  default     = []
}

variable "cloudfront_subject_alternative_names" {
  description = "Subject alternative names for CloudFront certificate"
  type        = list(string)
  default     = []
}

variable "alb_dns_name" {
  description = "ALB DNS name for Route53 records"
  type        = string
  default     = ""
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID for Route53 records"
  type        = string
  default     = ""
}

variable "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  type        = string
  default     = ""
}

variable "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID"
  type        = string
  default     = ""
}

variable "enable_health_check" {
  description = "Enable Route53 health checks"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
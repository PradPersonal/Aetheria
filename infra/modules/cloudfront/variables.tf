variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for origin"
  type        = string
}

variable "s3_bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  type        = string
}

variable "aliases" {
  description = "List of CNAME aliases for the distribution"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
}

variable "price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_All"
}

variable "enable_logging" {
  description = "Enable CloudFront access logs"
  type        = bool
  default     = false
}

variable "logs_bucket_domain_name" {
  description = "S3 bucket domain name for access logs"
  type        = string
  default     = ""
}

variable "enable_signed_urls" {
  description = "Enable signed URLs for premium content"
  type        = bool
  default     = false
}

variable "geo_restriction_type" {
  description = "Type of geo restriction (none, whitelist, blacklist)"
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "List of country codes for geo restrictions"
  type        = list(string)
  default     = []
}

variable "waf_web_acl_arn" {
  description = "WAF Web ACL ARN to associate with CloudFront"
  type        = string
  default     = null
}

variable "security_headers_function_arn" {
  description = "CloudFront function ARN for security headers"
  type        = string
  default     = ""
}

variable "create_security_headers_function" {
  description = "Create CloudFront function for security headers"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
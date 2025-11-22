variable "enable_alb_waf" {
  description = "Whether to enable WAF association for ALB."
  type        = bool
  default     = false
}
variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "enable_access_logs" {
  description = "Enable ALB access logs"
  type        = bool
  default     = false
}

variable "logs_bucket_name" {
  description = "S3 bucket name for access logs"
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "Health check path for web target group"
  type        = string
  default     = "/health"
}

variable "api_hostnames" {
  description = "List of API hostnames for listener rules"
  type        = list(string)
  default     = []
}

variable "waf_web_acl_arn" {
  description = "WAF Web ACL ARN to associate with ALB"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
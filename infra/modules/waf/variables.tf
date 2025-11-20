variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "enable_cloudfront_waf" {
  description = "Enable WAF for CloudFront distribution"
  type        = bool
  default     = false
}

variable "enable_alb_waf" {
  description = "Enable WAF for Application Load Balancer"
  type        = bool
  default     = false
}

variable "enable_rate_limiting" {
  description = "Enable rate limiting rules"
  type        = bool
  default     = true
}

variable "rate_limit_requests" {
  description = "Number of requests per 5-minute period before blocking"
  type        = number
  default     = 2000
}

variable "blocked_countries" {
  description = "List of country codes to block (ISO 3166-1 alpha-2)"
  type        = list(string)
  default     = []
}

variable "enable_waf_logging" {
  description = "Enable WAF logging to CloudWatch"
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN for WAF logs"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
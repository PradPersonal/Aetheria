variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "media_bucket_name" {
  description = "S3 bucket name for media files"
  type        = string
}

variable "logs_bucket_name" {
  description = "S3 bucket name for logs"
  type        = string
}

variable "media_bucket_lifecycle_days" {
  description = "Number of days before transitioning to IA storage class"
  type        = number
  default     = 30
}

variable "logs_bucket_lifecycle_days" {
  description = "Number of days before deleting log files"
  type        = number
  default     = 90
}

variable "allowed_origins" {
  description = "Allowed CORS origins for media bucket"
  type        = list(string)
  default     = []
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN for IRSA"
  type        = string
}

variable "service_accounts" {
  description = "List of namespace:service-account pairs for IRSA"
  type        = list(string)
  default = [
    "aetheria:streaming-service",
    "aetheria:media-processor"
  ]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
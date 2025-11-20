variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "ecr_repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default = [
    "aetheria-web",
    "aetheria-auth-service",
    "aetheria-chat-service",
    "aetheria-core-api-service",
    "aetheria-streaming-service"
  ]
}

variable "cluster_iam_role_arn" {
  description = "EKS cluster IAM role ARN for ECR access"
  type        = string
}

variable "node_group_iam_role_name" {
  description = "EKS node group IAM role name for policy attachment"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
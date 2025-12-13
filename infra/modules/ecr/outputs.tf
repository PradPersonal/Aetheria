output "ecr_repository_arns" {
  description = "ARNs of the ECR repositories"
  value       = { for k, v in aws_ecr_repository.services : k => v.arn }
}

output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value       = { for k, v in aws_ecr_repository.services : k => v.repository_url }
}

output "ecr_repositories" {
  description = "Map of ECR repository details"
  value       = aws_ecr_repository.services
}

output "ecr_access_policy_arn" {
  description = "ARN of the ECR access policy"
  value       = aws_iam_policy.ecr_access.arn
}
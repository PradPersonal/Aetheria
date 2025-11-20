output "media_bucket_id" {
  description = "ID of the media S3 bucket"
  value       = aws_s3_bucket.media.id
}

output "media_bucket_arn" {
  description = "ARN of the media S3 bucket"
  value       = aws_s3_bucket.media.arn
}

output "media_bucket_domain_name" {
  description = "Domain name of the media S3 bucket"
  value       = aws_s3_bucket.media.bucket_domain_name
}

output "media_bucket_regional_domain_name" {
  description = "Regional domain name of the media S3 bucket"
  value       = aws_s3_bucket.media.bucket_regional_domain_name
}

output "logs_bucket_id" {
  description = "ID of the logs S3 bucket"
  value       = aws_s3_bucket.logs.id
}

output "logs_bucket_arn" {
  description = "ARN of the logs S3 bucket"
  value       = aws_s3_bucket.logs.arn
}

output "s3_access_role_arn" {
  description = "IAM role ARN for S3 access via IRSA"
  value       = module.s3_access_irsa.iam_role_arn
}

output "s3_media_access_policy_arn" {
  description = "ARN of the S3 media access policy"
  value       = aws_iam_policy.s3_media_access.arn
}
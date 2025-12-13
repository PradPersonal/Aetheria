output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.media.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.media.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.media.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID"
  value       = aws_cloudfront_distribution.media.hosted_zone_id
}

output "cloudfront_origin_access_control_id" {
  description = "CloudFront Origin Access Control ID"
  value       = aws_cloudfront_origin_access_control.media.id
}

output "security_headers_function_arn" {
  description = "CloudFront function ARN for security headers"
  value       = var.create_security_headers_function ? aws_cloudfront_function.security_headers[0].arn : ""
}

output "cache_policy_ids" {
  description = "Map of cache policy IDs"
  value = {
    default = aws_cloudfront_cache_policy.default.id
    video   = aws_cloudfront_cache_policy.video.id
    image   = aws_cloudfront_cache_policy.image.id
  }
}
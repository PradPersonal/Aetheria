output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "route53_zone_arn" {
  description = "Route53 hosted zone ARN"
  value       = aws_route53_zone.main.arn
}

output "route53_zone_name_servers" {
  description = "Route53 hosted zone name servers"
  value       = aws_route53_zone.main.name_servers
}

output "alb_certificate_arn" {
  description = "ARN of the validated ALB certificate"
  value       = aws_acm_certificate_validation.alb.certificate_arn
}

output "cloudfront_certificate_arn" {
  description = "ARN of the validated CloudFront certificate"
  value       = aws_acm_certificate_validation.cloudfront.certificate_arn
}

output "main_domain_fqdn" {
  description = "FQDN of the main domain record"
  value       = length(aws_route53_record.main) > 0 ? aws_route53_record.main[0].fqdn : ""
}

output "api_domain_fqdn" {
  description = "FQDN of the API domain record"
  value       = length(aws_route53_record.api) > 0 ? aws_route53_record.api[0].fqdn : ""
}

output "cdn_domain_fqdn" {
  description = "FQDN of the CDN domain record"
  value       = length(aws_route53_record.cdn) > 0 ? aws_route53_record.cdn[0].fqdn : ""
}

output "health_check_id" {
  description = "Route53 health check ID"
  value       = length(aws_route53_health_check.main) > 0 ? aws_route53_health_check.main[0].id : ""
}
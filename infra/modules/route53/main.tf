# Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = merge(var.tags, {
    Purpose = "Main DNS Zone"
  })
}

# ACM Certificate for ALB (Regional)
resource "aws_acm_certificate" "alb" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = var.alb_subject_alternative_names

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name    = "${var.name}-alb-cert"
    Purpose = "ALB SSL Certificate"
  })
}

# ACM Certificate for CloudFront (us-east-1)
resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us_east_1

  domain_name       = var.cdn_domain_name
  validation_method = "DNS"

  subject_alternative_names = var.cloudfront_subject_alternative_names

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name    = "${var.name}-cloudfront-cert"
    Purpose = "CloudFront SSL Certificate"
  })
}

# Route 53 records for ACM certificate validation (ALB)
resource "aws_route53_record" "alb_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# Route 53 records for ACM certificate validation (CloudFront)
resource "aws_route53_record" "cloudfront_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# ACM certificate validation (ALB)
resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for record in aws_route53_record.alb_cert_validation : record.fqdn]
  
  timeouts {
    create = "5m"
  }
}

# ACM certificate validation (CloudFront)
resource "aws_acm_certificate_validation" "cloudfront" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_cert_validation : record.fqdn]
  
  timeouts {
    create = "5m"
  }
}

# Route 53 record for main domain (will point to ALB)
resource "aws_route53_record" "main" {
  count   = var.alb_dns_name != "" ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Route 53 record for API domain (will point to ALB)
resource "aws_route53_record" "api" {
  count   = var.alb_dns_name != "" && var.api_domain_name != "" ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = var.api_domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Route 53 record for CDN domain (will point to CloudFront)
resource "aws_route53_record" "cdn" {
  count   = var.cloudfront_domain_name != "" && var.cloudfront_hosted_zone_id != "" ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = var.cdn_domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# Health check for main domain
resource "aws_route53_health_check" "main" {
  count                           = var.enable_health_check ? 1 : 0
  fqdn                            = var.domain_name
  port                            = 443
  type                            = "HTTPS_STR_MATCH"
  resource_path                   = "/health"
  failure_threshold               = "3"
  request_interval                = "30"
  search_string                   = "OK"
  cloudwatch_logs_region          = var.aws_region
  enable_sni                      = true
  measure_latency                 = true
  invert_healthcheck             = false

  tags = merge(var.tags, {
    Name = "${var.name}-main-health-check"
  })
}

# CloudWatch alarm for health check
resource "aws_cloudwatch_metric_alarm" "health_check" {
  count               = var.enable_health_check ? 1 : 0
  alarm_name          = "${var.name}-health-check-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "This metric monitors health check status"

  dimensions = {
    HealthCheckId = aws_route53_health_check.main[0].id
  }

  tags = var.tags
}

# Provider for us-east-1 (required for CloudFront certificates)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
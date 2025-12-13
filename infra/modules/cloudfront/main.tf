# CloudFront Origin Access Control for S3
resource "aws_cloudfront_origin_access_control" "media" {
  name                              = "${var.name}-media-oac"
  description                       = "OAC for media S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution for media files
resource "aws_cloudfront_distribution" "media" {
  origin {
    domain_name              = var.s3_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.media.id
    origin_id                = "S3-${var.s3_bucket_name}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Aetheria media distribution"
  default_root_object = "index.html"
  price_class         = var.price_class

  # Logging configuration
  dynamic "logging_config" {
    for_each = var.enable_logging ? [1] : []
    content {
      include_cookies = false
      bucket          = var.logs_bucket_domain_name
      prefix          = "cloudfront/"
    }
  }

  # Aliases
  aliases = var.aliases

  # Default cache behavior
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.s3_bucket_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = aws_cloudfront_cache_policy.default.id
    
    # Enable signed URLs/cookies for premium content
    trusted_signers = var.enable_signed_urls ? [data.aws_caller_identity.current.account_id] : []

    dynamic "function_association" {
      for_each = var.security_headers_function_arn != "" ? [1] : []
      content {
        event_type   = "viewer-request"
        function_arn = var.security_headers_function_arn
      }
    }
  }

  # Cache behavior for videos
  ordered_cache_behavior {
    path_pattern           = "/videos/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.s3_bucket_name}"
    compress               = false
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = aws_cloudfront_cache_policy.video.id

    # Enable signed URLs for video content
    trusted_signers = var.enable_signed_urls ? [data.aws_caller_identity.current.account_id] : []
  }

  # Cache behavior for images
  ordered_cache_behavior {
    path_pattern           = "/images/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.s3_bucket_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = aws_cloudfront_cache_policy.image.id
  }

  # Geographic restrictions
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  # SSL certificate
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # WAF association
  web_acl_id = var.waf_web_acl_arn

  tags = var.tags

  depends_on = [
    aws_cloudfront_cache_policy.default,
    aws_cloudfront_cache_policy.video,
    aws_cloudfront_cache_policy.image
  ]
}

# Cache policies
resource "aws_cloudfront_cache_policy" "default" {
  name        = "${var.name}-default-cache-policy"
  comment     = "Default cache policy for media content"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

resource "aws_cloudfront_cache_policy" "video" {
  name        = "${var.name}-video-cache-policy"
  comment     = "Cache policy optimized for video streaming"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = false
    enable_accept_encoding_gzip   = false

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Range", "Accept-Ranges"]
      }
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

resource "aws_cloudfront_cache_policy" "image" {
  name        = "${var.name}-image-cache-policy"
  comment     = "Cache policy optimized for images"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Accept", "Accept-Language"]
      }
    }

    query_strings_config {
      query_string_behavior = "whitelist"
      query_strings {
        items = ["w", "h", "q", "format"]
      }
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

# Security headers function
resource "aws_cloudfront_function" "security_headers" {
  count   = var.create_security_headers_function ? 1 : 0
  name    = "${var.name}-security-headers"
  runtime = "cloudfront-js-1.0"
  comment = "Add security headers to responses"
  publish = true
  code    = file("${path.module}/functions/security-headers.js")
}

# Data sources
data "aws_caller_identity" "current" {}
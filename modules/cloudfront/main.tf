# CloudFront Module - Phase 3 신규 모듈
# us-east-1 Provider 사용 필수 (모듈 호출 시 providers 전달)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# CloudFront Distribution
# -----------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.name_prefix} CDN - Phase 3"
  default_root_object = "index.html"
  aliases             = var.domain_aliases
  price_class         = var.price_class

  # Origin 설정 - ALB DNS 직접 참조 금지!
  # Route53에서 origin-{env}.{domain} → ALIAS → ALB 로 연결된 도메인 사용
  origin {
    domain_name = var.origin_domain
    origin_id   = "alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout    = 60
    }
  }

  # S3 이미지 Origin (Lambda@Edge 이미지 리사이징용)
  dynamic "origin" {
    for_each = var.enable_image_resize && var.image_bucket_domain_name != "" ? [1] : []
    content {
      domain_name              = var.image_bucket_domain_name
      origin_id                = "s3-image-origin"
      origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac[0].id
    }
  }


  # 기본 캐시 동작
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id          = aws_cloudfront_cache_policy.default.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.default.id
  }

  # 정적 자산 캐시 동작 (선택사항)
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id = aws_cloudfront_cache_policy.static.id
  }

  ordered_cache_behavior {
    path_pattern           = "/_next/static/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id = aws_cloudfront_cache_policy.static.id
  }

  # 이미지 리사이징 캐시 동작 (Lambda@Edge 연결)
  dynamic "ordered_cache_behavior" {
    for_each = var.enable_image_resize ? [1] : []
    content {
      path_pattern           = "/images/*"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      target_origin_id       = "s3-image-origin"
      viewer_protocol_policy = "redirect-to-https"
      compress               = true

      cache_policy_id          = aws_cloudfront_cache_policy.image[0].id
      origin_request_policy_id = aws_cloudfront_origin_request_policy.image[0].id

      # Lambda@Edge 연결
      dynamic "lambda_function_association" {
        for_each = var.lambda_edge_viewer_request_arn != "" ? [1] : []
        content {
          event_type   = "viewer-request"
          lambda_arn   = var.lambda_edge_viewer_request_arn
          include_body = false
        }
      }

      dynamic "lambda_function_association" {
        for_each = var.lambda_edge_origin_response_arn != "" ? [1] : []
        content {
          event_type   = "origin-response"
          lambda_arn   = var.lambda_edge_origin_response_arn
          include_body = true
        }
      }
    }
  }


  # SSL 인증서 (us-east-1 ACM 필수)
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # WAF 연결 (선택사항 - Global WAF)
  web_acl_id = var.waf_global_arn != "" ? var.waf_global_arn : null

  # 로깅 (선택사항)
  dynamic "logging_config" {
    for_each = var.enable_logging && var.logs_bucket_domain != "" ? [1] : []
    content {
      include_cookies = false
      bucket          = var.logs_bucket_domain
      prefix          = "cloudfront/${var.environment}/"
    }
  }

  tags = merge(var.tags, {
    Name  = "${var.name_prefix}-cloudfront"
    Phase = "3"
  })
}

# -----------------------------------------------------------------------------
# Cache Policy - 기본
# -----------------------------------------------------------------------------
resource "aws_cloudfront_cache_policy" "default" {
  name        = "${var.name_prefix}-cache-policy-default"
  comment     = "Default cache policy for dynamic content"
  min_ttl     = 0
  default_ttl = var.default_ttl
  max_ttl     = 31536000 # 1년

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# -----------------------------------------------------------------------------
# Cache Policy - 정적 자산 (장기 캐시)
# -----------------------------------------------------------------------------
resource "aws_cloudfront_cache_policy" "static" {
  name        = "${var.name_prefix}-cache-policy-static"
  comment     = "Long-term cache for static assets"
  min_ttl     = 86400    # 1일
  default_ttl = 604800   # 7일
  max_ttl     = 31536000 # 1년

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# -----------------------------------------------------------------------------
# Origin Request Policy
# -----------------------------------------------------------------------------
resource "aws_cloudfront_origin_request_policy" "default" {
  name    = "${var.name_prefix}-origin-request-policy"
  comment = "Forward necessary headers to origin"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Host", "Origin", "Accept", "Accept-Language"]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

# =============================================================================
# Lambda@Edge 이미지 리사이징 관련 리소스
# =============================================================================

# -----------------------------------------------------------------------------
# S3 Origin Access Control (OAC)
# CloudFront → S3 프라이빗 액세스
# -----------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  count = var.enable_image_resize ? 1 : 0

  name                              = "${var.name_prefix}-s3-oac"
  description                       = "OAC for S3 image bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# -----------------------------------------------------------------------------
# Cache Policy - 이미지 (장기 캐시 + WebP 지원)
# -----------------------------------------------------------------------------
resource "aws_cloudfront_cache_policy" "image" {
  count = var.enable_image_resize ? 1 : 0

  name        = "${var.name_prefix}-cache-policy-image"
  comment     = "Long-term cache for resized images"
  min_ttl     = 86400 # 1일
  default_ttl = var.image_cache_ttl
  max_ttl     = 31536000 # 1년

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Accept"] # WebP 지원 감지용
      }
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# -----------------------------------------------------------------------------
# Origin Request Policy - 이미지
# -----------------------------------------------------------------------------
resource "aws_cloudfront_origin_request_policy" "image" {
  count = var.enable_image_resize ? 1 : 0

  name    = "${var.name_prefix}-origin-request-policy-image"
  comment = "Forward Accept header for WebP detection"

  cookies_config {
    cookie_behavior = "none"
  }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Accept", "Origin"]
    }
  }

  query_strings_config {
    query_string_behavior = "none"
  }
}


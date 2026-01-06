# WAF Module - Phase 3 신규 모듈 (Regional WAF for ALB)
# ap-southeast-2 (Sydney) 리전용 - REGIONAL scope

resource "aws_wafv2_web_acl" "main" {
  name        = "${var.name_prefix}-waf"
  scope       = "REGIONAL"
  description = "WAF for ALB protection - Phase 3"

  default_action {
    allow {}
  }

  # Rule 1: AWS Core Rule Set (필수)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-CommonRuleSet"
    }
  }

  # Rule 2: SQL Injection 방어 (필수)
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-SQLiRuleSet"
    }
  }

  # Rule 3: Known Bad Inputs (필수)
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-BadInputsRuleSet"
    }
  }

  # Rule 4: Rate Limiting (커스텀)
  rule {
    name     = "RateLimitRule"
    priority = 10

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-RateLimit"
    }
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf"
  }

  tags = merge(var.tags, {
    Name  = "${var.name_prefix}-waf"
    Phase = "3"
  })
}

# WAF → ALB 연결
# ⚠️ 권장: Terraform 대신 Ingress Annotation 사용
# Ingress에 아래 annotation 추가:
#   alb.ingress.kubernetes.io/wafv2-acl-arn: "${aws_wafv2_web_acl.main.arn}"
#
# 장점:
# - ALB 재생성 시 자동 재연결
# - Terraform-Ingress 의존성 제거
#
# Terraform으로 연결하려면 (비권장):
resource "aws_wafv2_web_acl_association" "alb" {
  count = var.enable_waf_association && var.alb_arn != "" ? 1 : 0

  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# WAF 로깅 설정 (선택사항 - S3 로그)
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  count = var.enable_waf_logging && var.waf_logs_bucket_arn != "" ? 1 : 0

  log_destination_configs = [var.waf_logs_bucket_arn]
  resource_arn            = aws_wafv2_web_acl.main.arn

  # 기본: 차단된 요청만 로깅 (비용 절감)
  # 운영 초기에는 logging_filter 제거하여 모든 요청 로깅 권장
  logging_filter {
    default_behavior = "DROP"

    filter {
      behavior    = "KEEP"
      requirement = "MEETS_ANY"

      condition {
        action_condition {
          action = "BLOCK"
        }
      }
    }
  }
}

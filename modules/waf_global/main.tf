# WAF Global Module - CloudFront용 (us-east-1)
# ⚠️ 이 모듈은 반드시 us-east-1 provider로 호출해야 함
# CloudFront 배포에 연결되는 Global WAF

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_wafv2_web_acl" "global" {
  name        = "${var.name_prefix}-global-waf"
  scope       = "CLOUDFRONT"  # ← Global WAF
  description = "Global WAF for CloudFront - All environments (ISMS-P Compliant)"

  default_action {
    allow {}
  }

  # Rule 1: AWS Core Rule Set
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

  # Rule 2: SQL Injection 방어
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

  # Rule 3: Known Bad Inputs
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

  # Rule 4: XSS 방어 (ISMS-P 2.9.3)
  rule {
    name     = "AWSManagedRulesXSSRuleSet"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesXSSRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-XSSRuleSet"
    }
  }

  # Rule 5: Linux 서버 취약점 방어 (ISMS-P 2.9.3)
  rule {
    name     = "AWSManagedRulesLinuxRuleSet"
    priority = 5

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-LinuxRuleSet"
    }
  }

  # Rule 6: IP Reputation 차단 (ISMS-P 2.9.4)
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 6

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-IpReputationList"
    }
  }

  # Rule 10: Rate Limiting (DDoS 방어)
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
    metric_name                = "${var.name_prefix}-global-waf"
  }

  tags = merge(var.tags, {
    Name       = "${var.name_prefix}-global-waf"
    Scope      = "CLOUDFRONT"
    Phase      = "3"
    Compliance = "ISMS-P"
  })
}

# WAF 로깅 설정 (S3로 로그 전송)
resource "aws_wafv2_web_acl_logging_configuration" "global" {
  count = var.enable_logging ? 1 : 0

  log_destination_configs = [var.waf_logs_bucket_arn]
  resource_arn            = aws_wafv2_web_acl.global.arn

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

# =============================================================================
# Log Analytics Module: 메인 리소스
# EventBridge, Athena, S3 리포트 버킷
# =============================================================================

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# 리포트 저장용 S3 버킷
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "reports" {
  bucket = var.report_bucket_name != "" ? var.report_bucket_name : "${var.name_prefix}-log-reports"

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-log-reports"
    Purpose = "ai-generated-reports"
    ISMS-P  = "2.10.1-log-retention"
  })
}

resource "aws_s3_bucket_versioning" "reports" {
  bucket = aws_s3_bucket.reports.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reports" {
  bucket = aws_s3_bucket.reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "reports" {
  bucket = aws_s3_bucket.reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ISMS-P 2.10.1: 로그 최소 1년 보관 후 Glacier로 전환
resource "aws_s3_bucket_lifecycle_configuration" "reports" {
  bucket = aws_s3_bucket.reports.id

  rule {
    id     = "isms-p-retention"
    status = "Enabled"

    filter {}

    # 90일 후 IA로 전환 (비용 절감)
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    # 1년 후 Glacier로 전환
    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    # 7년 후 삭제 (ISMS-P 규정 준수)
    expiration {
      days = 2555
    }
  }
}

# -----------------------------------------------------------------------------
# Athena Workgroup (로그 쿼리용)
# -----------------------------------------------------------------------------
resource "aws_athena_workgroup" "logs" {
  name = "${var.name_prefix}-log-analytics"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.reports.id}/athena-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    # 비용 통제: 쿼리당 최대 100MB
    bytes_scanned_cutoff_per_query = 104857600
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-log-analytics"
  })
}

# Athena 데이터베이스
resource "aws_athena_database" "logs" {
  name   = replace("${var.name_prefix}_logs", "-", "_")
  bucket = aws_s3_bucket.reports.id

  encryption_configuration {
    encryption_option = "SSE_S3"
  }
}

# -----------------------------------------------------------------------------
# EventBridge: 정기 리포트 스케줄
# -----------------------------------------------------------------------------

# 일간 리포트 (매일 한국시간 09:00 = UTC 00:00)
resource "aws_cloudwatch_event_rule" "daily_report" {
  count = var.enable_daily_report ? 1 : 0

  name                = "${var.name_prefix}-daily-report"
  description         = "일간 보안 리포트 생성 트리거"
  schedule_expression = "cron(0 ${var.daily_report_hour} * * ? *)"

  tags = merge(var.tags, {
    Name     = "${var.name_prefix}-daily-report"
    Schedule = "daily"
  })
}

resource "aws_cloudwatch_event_target" "daily_report" {
  count = var.enable_daily_report ? 1 : 0

  rule      = aws_cloudwatch_event_rule.daily_report[0].name
  target_id = "daily-report-lambda"
  arn       = aws_lambda_function.report_generator.arn

  input = jsonencode({
    report_type = "daily"
    channel     = var.slack_channel
  })
}

# 주간 리포트 (매주 월요일 09:00)
resource "aws_cloudwatch_event_rule" "weekly_report" {
  count = var.enable_weekly_report ? 1 : 0

  name                = "${var.name_prefix}-weekly-report"
  description         = "주간 보안 리포트 생성 트리거"
  schedule_expression = "cron(0 ${var.daily_report_hour} ? * MON *)"

  tags = merge(var.tags, {
    Name     = "${var.name_prefix}-weekly-report"
    Schedule = "weekly"
  })
}

resource "aws_cloudwatch_event_target" "weekly_report" {
  count = var.enable_weekly_report ? 1 : 0

  rule      = aws_cloudwatch_event_rule.weekly_report[0].name
  target_id = "weekly-report-lambda"
  arn       = aws_lambda_function.report_generator.arn

  input = jsonencode({
    report_type = "weekly"
    channel     = var.slack_channel
  })
}

# 월간 리포트 (매월 1일 09:00)
resource "aws_cloudwatch_event_rule" "monthly_report" {
  count = var.enable_monthly_report ? 1 : 0

  name                = "${var.name_prefix}-monthly-report"
  description         = "월간 보안 리포트 생성 트리거"
  schedule_expression = "cron(0 ${var.daily_report_hour} 1 * ? *)"

  tags = merge(var.tags, {
    Name     = "${var.name_prefix}-monthly-report"
    Schedule = "monthly"
  })
}

resource "aws_cloudwatch_event_target" "monthly_report" {
  count = var.enable_monthly_report ? 1 : 0

  rule      = aws_cloudwatch_event_rule.monthly_report[0].name
  target_id = "monthly-report-lambda"
  arn       = aws_lambda_function.report_generator.arn

  input = jsonencode({
    report_type = "monthly"
    channel     = var.slack_channel
  })
}

# -----------------------------------------------------------------------------
# EventBridge: 실시간 보안 이벤트 모니터링 (ISMS-P)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "security_events" {
  name        = "${var.name_prefix}-security-events"
  description = "ISMS-P 보안 이벤트 실시간 모니터링"

  event_pattern = jsonencode({
    source      = ["aws.cloudtrail"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = var.security_events
    }
  })

  tags = merge(var.tags, {
    Name   = "${var.name_prefix}-security-events"
    ISMS-P = "realtime-monitoring"
  })
}

resource "aws_cloudwatch_event_target" "security_events" {
  rule      = aws_cloudwatch_event_rule.security_events.name
  target_id = "security-alert-lambda"
  arn       = aws_lambda_function.realtime_alert.arn
}

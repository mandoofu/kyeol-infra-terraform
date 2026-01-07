# =============================================================================
# Log Analytics Module: Lambda 함수 정의
# 정기 리포트 생성 + 실시간 알람
# =============================================================================

# -----------------------------------------------------------------------------
# Lambda 소스 코드 패키징
# -----------------------------------------------------------------------------
data "archive_file" "report_generator" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code/report_generator"
  output_path = "${path.module}/lambda_code/report_generator.zip"
}

data "archive_file" "realtime_alert" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code/realtime_alert"
  output_path = "${path.module}/lambda_code/realtime_alert.zip"
}

# -----------------------------------------------------------------------------
# 정기 리포트 생성 Lambda
# Athena 쿼리 → Bedrock AI 분석 → S3 저장 → Slack 알림
# -----------------------------------------------------------------------------
resource "aws_lambda_function" "report_generator" {
  function_name = "${var.name_prefix}-report-generator"
  description   = "AI 기반 일/주/월 보안 리포트 자동 생성"

  filename         = data.archive_file.report_generator.output_path
  source_code_hash = data.archive_file.report_generator.output_base64sha256
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 300 # 5분 (Athena 쿼리 대기)
  memory_size      = 512

  role = aws_iam_role.lambda_execution.arn

  environment {
    variables = {
      AUDIT_BUCKET       = var.audit_bucket_name
      REPORT_BUCKET      = aws_s3_bucket.reports.id
      ATHENA_WORKGROUP   = aws_athena_workgroup.logs.name
      ATHENA_DATABASE    = aws_athena_database.logs.name
      BEDROCK_MODEL_ID   = var.bedrock_model_id
      BEDROCK_REGION     = var.bedrock_region
      SLACK_SECRET_ARN   = aws_secretsmanager_secret.slack_webhook.arn
      SLACK_CHANNEL      = var.slack_channel
      AWS_ACCOUNT_ID     = var.aws_account_id
      LOG_RETENTION_DAYS = tostring(var.log_retention_days)
    }
  }

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-report-generator"
    Purpose = "ai-report-generation"
  })
}

# EventBridge 트리거 권한
resource "aws_lambda_permission" "daily_report" {
  count = var.enable_daily_report ? 1 : 0

  statement_id  = "AllowDailyReportTrigger"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.report_generator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_report[0].arn
}

resource "aws_lambda_permission" "weekly_report" {
  count = var.enable_weekly_report ? 1 : 0

  statement_id  = "AllowWeeklyReportTrigger"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.report_generator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_report[0].arn
}

resource "aws_lambda_permission" "monthly_report" {
  count = var.enable_monthly_report ? 1 : 0

  statement_id  = "AllowMonthlyReportTrigger"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.report_generator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monthly_report[0].arn
}

# -----------------------------------------------------------------------------
# 실시간 보안 알람 Lambda
# CloudTrail 보안 이벤트 감지 → 즉시 Slack 알림
# -----------------------------------------------------------------------------
resource "aws_lambda_function" "realtime_alert" {
  function_name = "${var.name_prefix}-realtime-alert"
  description   = "ISMS-P 보안 이벤트 실시간 Slack 알람"

  filename         = data.archive_file.realtime_alert.output_path
  source_code_hash = data.archive_file.realtime_alert.output_base64sha256
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256

  role = aws_iam_role.lambda_execution.arn

  environment {
    variables = {
      SLACK_SECRET_ARN = aws_secretsmanager_secret.slack_webhook.arn
      SLACK_CHANNEL    = var.slack_channel
    }
  }

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-realtime-alert"
    Purpose = "isms-p-security-monitoring"
  })
}

# EventBridge 트리거 권한
resource "aws_lambda_permission" "security_events" {
  statement_id  = "AllowSecurityEventsTrigger"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.realtime_alert.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.security_events.arn
}

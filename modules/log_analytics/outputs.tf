# =============================================================================
# Log Analytics Module: 출력값
# =============================================================================

output "report_bucket_id" {
  description = "리포트 저장 S3 버킷 ID"
  value       = aws_s3_bucket.reports.id
}

output "report_bucket_arn" {
  description = "리포트 저장 S3 버킷 ARN"
  value       = aws_s3_bucket.reports.arn
}

output "athena_workgroup_name" {
  description = "Athena Workgroup 이름"
  value       = aws_athena_workgroup.logs.name
}

output "athena_database_name" {
  description = "Athena 데이터베이스 이름"
  value       = aws_athena_database.logs.name
}

output "report_generator_lambda_arn" {
  description = "정기 리포트 생성 Lambda ARN"
  value       = aws_lambda_function.report_generator.arn
}

output "realtime_alert_lambda_arn" {
  description = "실시간 알람 Lambda ARN"
  value       = aws_lambda_function.realtime_alert.arn
}

output "slack_secret_arn" {
  description = "Slack Webhook Secret ARN"
  value       = aws_secretsmanager_secret.slack_webhook.arn
}

output "eventbridge_rules" {
  description = "EventBridge 스케줄 규칙 목록"
  value = {
    daily    = var.enable_daily_report ? aws_cloudwatch_event_rule.daily_report[0].name : null
    weekly   = var.enable_weekly_report ? aws_cloudwatch_event_rule.weekly_report[0].name : null
    monthly  = var.enable_monthly_report ? aws_cloudwatch_event_rule.monthly_report[0].name : null
    security = aws_cloudwatch_event_rule.security_events.name
  }
}

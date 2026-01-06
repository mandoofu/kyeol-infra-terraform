# CloudTrail Module Outputs

output "cloudtrail_arn" {
  description = "CloudTrail ARN"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].arn : null
}

output "cloudtrail_id" {
  description = "CloudTrail ID"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].id : null
}

output "audit_bucket_id" {
  description = "Audit 로그 버킷 ID"
  value       = var.enable_cloudtrail ? aws_s3_bucket.audit[0].id : null
}

output "audit_bucket_arn" {
  description = "Audit 로그 버킷 ARN"
  value       = var.enable_cloudtrail ? aws_s3_bucket.audit[0].arn : null
}

output "cloudwatch_log_group_arn" {
  description = "CloudTrail CloudWatch Log Group ARN"
  value       = var.enable_cloudtrail && var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.cloudtrail[0].arn : null
}

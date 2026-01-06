# S3 Module Outputs

output "media_bucket_id" {
  description = "미디어 버킷 ID"
  value       = var.create_media_bucket ? aws_s3_bucket.media[0].id : null
}

output "media_bucket_arn" {
  description = "미디어 버킷 ARN"
  value       = var.create_media_bucket ? aws_s3_bucket.media[0].arn : null
}

output "media_bucket_domain_name" {
  description = "미디어 버킷 도메인"
  value       = var.create_media_bucket ? aws_s3_bucket.media[0].bucket_regional_domain_name : null
}

output "logs_bucket_id" {
  description = "로그 버킷 ID"
  value       = var.create_logs_bucket ? aws_s3_bucket.logs[0].id : null
}

output "logs_bucket_arn" {
  description = "로그 버킷 ARN"
  value       = var.create_logs_bucket ? aws_s3_bucket.logs[0].arn : null
}

output "waf_logs_bucket_arn" {
  description = "WAF 로그 버킷 ARN"
  value       = var.create_waf_logs_bucket ? aws_s3_bucket.waf_logs[0].arn : null
}

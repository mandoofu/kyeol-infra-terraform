# WAF Global Module Outputs

output "web_acl_arn" {
  description = "Global WAF Web ACL ARN (CloudFront에 연결)"
  value       = aws_wafv2_web_acl.global.arn
}

output "web_acl_id" {
  description = "Global WAF Web ACL ID"
  value       = aws_wafv2_web_acl.global.id
}

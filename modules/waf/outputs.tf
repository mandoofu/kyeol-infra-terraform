# WAF Module Outputs

output "web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.main.arn
}

output "web_acl_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.main.id
}

output "web_acl_capacity" {
  description = "WAF Web ACL Capacity Units 사용량"
  value       = aws_wafv2_web_acl.main.capacity
}

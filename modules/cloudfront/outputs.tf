# CloudFront Module Outputs

output "distribution_id" {
  description = "CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "distribution_arn" {
  description = "CloudFront Distribution ARN"
  value       = aws_cloudfront_distribution.main.arn
}

output "distribution_domain_name" {
  description = "CloudFront Distribution 도메인 (예: d1234.cloudfront.net)"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "distribution_hosted_zone_id" {
  description = "CloudFront Distribution Hosted Zone ID (Route53 ALIAS용)"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "cache_policy_default_id" {
  description = "기본 Cache Policy ID"
  value       = aws_cloudfront_cache_policy.default.id
}

output "cache_policy_static_id" {
  description = "정적 자산 Cache Policy ID"
  value       = aws_cloudfront_cache_policy.static.id
}

# Lambda@Edge Module Outputs

output "function_arn" {
  description = "Lambda 함수 ARN"
  value       = aws_lambda_function.edge.arn
}

output "function_qualified_arn" {
  description = "Lambda 함수 버전 포함 ARN (CloudFront 연결용)"
  value       = aws_lambda_function.edge.qualified_arn
}

output "function_version" {
  description = "발행된 Lambda 함수 버전"
  value       = aws_lambda_function.edge.version
}

output "role_arn" {
  description = "Lambda IAM Role ARN"
  value       = aws_iam_role.lambda_edge.arn
}

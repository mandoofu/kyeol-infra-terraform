# Fluent Bit IRSA Outputs - Phase 3 추가

output "fluent_bit_role_arn" {
  description = "Fluent Bit IRSA Role ARN"
  value       = var.enable_fluent_bit_irsa ? aws_iam_role.fluent_bit[0].arn : null
}

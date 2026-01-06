# DEV Environment: 출력값

# VPC
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public 서브넷 ID 목록"
  value       = module.vpc.public_subnet_ids
}

output "app_private_subnet_ids" {
  description = "App Private 서브넷 ID 목록"
  value       = module.vpc.app_private_subnet_ids
}

output "data_private_subnet_ids" {
  description = "Data Private 서브넷 ID 목록"
  value       = module.vpc.data_private_subnet_ids
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway Public IP"
  value       = module.vpc.nat_gateway_public_ip
}

# EKS
output "eks_cluster_name" {
  description = "EKS 클러스터 이름"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS 클러스터 엔드포인트"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "EKS 클러스터 CA 인증서"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  description = "EKS OIDC Provider ARN"
  value       = module.eks.oidc_provider_arn
}

output "alb_controller_role_arn" {
  description = "AWS Load Balancer Controller IRSA 역할 ARN"
  value       = module.eks.alb_controller_role_arn
}

output "external_dns_role_arn" {
  description = "ExternalDNS IRSA 역할 ARN"
  value       = module.eks.external_dns_role_arn
}

output "kubeconfig_command" {
  description = "kubeconfig 설정 명령어"
  value       = module.eks.kubeconfig_command
}

# RDS
output "rds_endpoint" {
  description = "RDS 엔드포인트"
  value       = module.rds.db_instance_endpoint
}

output "rds_secret_arn" {
  description = "RDS 자격증명 Secrets Manager ARN"
  value       = module.rds.db_secret_arn
}

# ECR
output "ecr_repository_urls" {
  description = "ECR 리포지토리 URL 맵"
  value       = module.ecr.repository_urls
}

# =============================================================================
# Phase 3: 보안 & 모니터링 Outputs
# =============================================================================

# Fluent Bit IRSA
output "fluent_bit_role_arn" {
  description = "Fluent Bit IRSA Role ARN"
  value       = var.enable_fluent_bit_irsa ? module.eks.fluent_bit_role_arn : null
}

# S3
output "s3_media_bucket_id" {
  description = "미디어 버킷 ID"
  value       = var.enable_phase3_s3 ? module.s3_phase3[0].media_bucket_id : null
}

output "s3_logs_bucket_id" {
  description = "로그 버킷 ID"
  value       = var.enable_phase3_s3 ? module.s3_phase3[0].logs_bucket_id : null
}

# WAF/CloudFront → MGMT 환경에서 관리
# terraform output -state=../mgmt/terraform.tfstate global_waf_arn
# terraform output -state=../mgmt/terraform.tfstate cloudfront_domain_name

# CloudTrail
output "cloudtrail_arn" {
  description = "CloudTrail ARN"
  value       = var.enable_cloudtrail ? module.cloudtrail[0].cloudtrail_arn : null
}

output "audit_bucket_id" {
  description = "Audit 로그 버킷 ID"
  value       = var.enable_cloudtrail ? module.cloudtrail[0].audit_bucket_id : null
}

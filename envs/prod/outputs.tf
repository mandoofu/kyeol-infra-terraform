# PROD Environment Outputs

# VPC
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public 서브넷 IDs"
  value       = module.vpc.public_subnet_ids
}

output "app_private_subnet_ids" {
  description = "App Private 서브넷 IDs"
  value       = module.vpc.app_private_subnet_ids
}

output "data_private_subnet_ids" {
  description = "Data Private 서브넷 IDs"
  value       = module.vpc.data_private_subnet_ids
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

output "eks_cluster_security_group_id" {
  description = "EKS 클러스터 보안 그룹 ID"
  value       = module.eks.cluster_security_group_id
}

output "eks_oidc_provider_arn" {
  description = "EKS OIDC Provider ARN"
  value       = module.eks.oidc_provider_arn
}

output "alb_controller_role_arn" {
  description = "AWS Load Balancer Controller IRSA Role ARN"
  value       = module.eks.alb_controller_role_arn
}

output "external_dns_role_arn" {
  description = "ExternalDNS IRSA Role ARN"
  value       = module.eks.external_dns_role_arn
}

output "kubeconfig_command" {
  description = "kubeconfig 업데이트 명령"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# RDS (모듈 output 이름에 맞춤)
output "rds_endpoint" {
  description = "RDS 엔드포인트"
  value       = module.rds.db_instance_endpoint
}

output "rds_port" {
  description = "RDS 포트"
  value       = module.rds.db_instance_port
}

output "rds_secret_arn" {
  description = "RDS Credentials Secret ARN"
  value       = module.rds.db_secret_arn
  sensitive   = true
}

output "rds_deletion_protection" {
  description = "RDS 삭제 보호 상태"
  value       = var.rds_deletion_protection
}

# Valkey (모듈 output 이름에 맞춤)
output "valkey_endpoint" {
  description = "Valkey 엔드포인트"
  value       = var.enable_cache ? module.valkey[0].cache_endpoint : null
}

output "valkey_port" {
  description = "Valkey 포트"
  value       = var.enable_cache ? module.valkey[0].cache_port : null
}

# ECR
output "ecr_repository_urls" {
  description = "ECR 리포지토리 URLs"
  value       = module.ecr.repository_urls
}

# Production Critical Info
output "production_checklist" {
  description = "운영 체크리스트"
  value = {
    rds_multi_az            = var.rds_multi_az
    rds_deletion_protection = var.rds_deletion_protection
    rds_backup_days         = var.rds_backup_retention_period
    cache_failover          = var.enable_cache
    monitoring_enabled      = var.enable_enhanced_monitoring
    logging_enabled         = var.enable_cloudwatch_logs
  }
}

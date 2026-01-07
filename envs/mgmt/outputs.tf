# MGMT Environment: 출력값

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

output "nat_gateway_public_ip" {
  description = "NAT Gateway Public IP"
  value       = module.vpc.nat_gateway_public_ip
}

# =============================================================================
# VPC Peering용 출력값 (DEV/STAGE/PROD에서 참조)
# =============================================================================
output "vpc_cidr" {
  description = "MGMT VPC CIDR (VPC Peering용)"
  value       = var.vpc_cidr
}

output "private_route_table_id" {
  description = "MGMT Private Route Table ID (VPC Peering 라우팅용)"
  value       = module.vpc.private_route_table_id
}

output "all_route_table_ids" {
  description = "MGMT 모든 Route Table ID 목록"
  value       = module.vpc.all_route_table_ids
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

# =============================================================================
# Phase 3: Global WAF + CloudFront Outputs
# =============================================================================

output "global_waf_arn" {
  description = "Global WAF Web ACL ARN (모든 환경 공유)"
  value       = var.enable_global_waf ? module.waf_global[0].web_acl_arn : null
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = var.enable_cloudfront ? module.cloudfront[0].distribution_id : null
}

output "cloudfront_domain_name" {
  description = "CloudFront 도메인"
  value       = var.enable_cloudfront ? module.cloudfront[0].distribution_domain_name : null
}

output "waf_logs_bucket" {
  description = "Global WAF 로그 버킷 (us-east-1)"
  value       = var.enable_global_waf && var.enable_waf_logging ? aws_s3_bucket.waf_logs[0].id : null
}

# VPC Module: 출력값

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR 블록"
  value       = aws_vpc.main.cidr_block
}

# Subnet IDs
output "public_subnet_ids" {
  description = "Public 서브넷 ID 목록"
  value       = aws_subnet.public[*].id
}

output "app_private_subnet_ids" {
  description = "App Private 서브넷 ID 목록"
  value       = aws_subnet.app_private[*].id
}

output "data_private_subnet_ids" {
  description = "Data Private 서브넷 ID 목록"
  value       = aws_subnet.data_private[*].id
}

output "cache_private_subnet_ids" {
  description = "Cache Private 서브넷 ID 목록"
  value       = aws_subnet.cache_private[*].id
}

# NAT Gateway
output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway Public IP"
  value       = var.enable_nat_gateway ? aws_eip.nat[0].public_ip : null
}

# Internet Gateway
output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

# Security Groups
output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "rds_security_group_id" {
  description = "RDS Security Group ID"
  value       = length(aws_security_group.rds) > 0 ? aws_security_group.rds[0].id : null
}

output "cache_security_group_id" {
  description = "Cache Security Group ID"
  value       = length(aws_security_group.cache) > 0 ? aws_security_group.cache[0].id : null
}

# Route Tables
output "public_route_table_id" {
  description = "Public Route Table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Private Route Table ID"
  value       = aws_route_table.private.id
}

# AZ 정보
output "azs" {
  description = "사용된 가용영역 목록"
  value       = var.azs
}

# 결제 전용 NAT Gateway (PROD 전용)
output "payment_nat_public_ip" {
  description = "결제 전용 NAT Gateway Public IP (PG사 화이트리스트용)"
  value       = var.enable_payment_nat ? aws_eip.payment[0].public_ip : null
}

output "payment_route_table_id" {
  description = "결제 전용 Route Table ID"
  value       = var.enable_payment_nat ? aws_route_table.payment[0].id : null
}

output "payment_subnet_ids" {
  description = "결제 전용 서브넷 ID 목록"
  value       = aws_subnet.payment_private[*].id
}

# =============================================================================
# VPC Peering용 출력값
# =============================================================================
output "all_route_table_ids" {
  description = "모든 라우트 테이블 ID 목록 (VPC Peering 라우팅용)"
  value = compact([
    aws_route_table.public.id,
    aws_route_table.private.id,
    var.enable_payment_nat ? aws_route_table.payment[0].id : ""
  ])
}

# Valkey/Redis (ElastiCache) Module: 출력값
# Replication Group 기반 outputs

output "replication_group_id" {
  description = "Replication Group ID"
  value       = aws_elasticache_replication_group.main.id
}

output "replication_group_arn" {
  description = "Replication Group ARN"
  value       = aws_elasticache_replication_group.main.arn
}

output "primary_endpoint_address" {
  description = "Primary 엔드포인트 주소 (쓰기용)"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader 엔드포인트 주소 (읽기용, replica가 있을 때)"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

# 기존 호환용 outputs (envs/*/outputs.tf에서 참조)
output "cache_endpoint" {
  description = "캐시 Primary 엔드포인트 (기존 호환용)"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "cache_port" {
  description = "캐시 포트"
  value       = var.port
}

output "subnet_group_name" {
  description = "서브넷 그룹 이름"
  value       = aws_elasticache_subnet_group.main.name
}

# HA 상태 정보
output "ha_status" {
  description = "HA 구성 상태"
  value = {
    replicas_per_node_group    = var.replicas_per_node_group
    automatic_failover_enabled = aws_elasticache_replication_group.main.automatic_failover_enabled
    multi_az_enabled           = aws_elasticache_replication_group.main.multi_az_enabled
    node_type                  = var.node_type
  }
}

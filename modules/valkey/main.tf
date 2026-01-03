# Valkey/Redis (ElastiCache) Module: 메인 리소스
# Replication Group 기반으로 Stage/Prod HA 지원

locals {
  # replicas >= 1 이면 automatic_failover와 multi_az 강제 활성화
  effective_automatic_failover = var.replicas_per_node_group >= 1 ? true : var.automatic_failover_enabled
  effective_multi_az           = var.replicas_per_node_group >= 1 ? true : var.multi_az_enabled

  # Parameter Group 결정 (coalesce 사용 금지 - 전부 null이면 실패)
  # 우선순위: 명시 > 생성 > null(미지정)
  # create_parameter_group=false인 경우 tuple이 비어있어 인덱싱하면 안됨
  effective_parameter_group_name = (
    var.parameter_group_name != null ? var.parameter_group_name :
    (var.create_parameter_group ? aws_elasticache_parameter_group.main[0].name : null)
  )
}

# 서브넷 그룹
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.name_prefix}-cache-subnet"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cache-subnet"
  })
}

# 커스텀 Parameter Group (선택적 생성)
resource "aws_elasticache_parameter_group" "main" {
  count = var.create_parameter_group ? 1 : 0

  name   = "${var.name_prefix}-cache-params"
  family = var.parameter_group_family

  description = "Custom parameter group for ${var.name_prefix}"

  dynamic "parameter" {
    for_each = var.parameter_group_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cache-params"
  })
}

# Replication Group (HA 지원)
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.name_prefix}-cache"
  description          = "Valkey/Redis cache for ${var.name_prefix}"

  engine         = var.engine
  engine_version = var.engine_version
  node_type      = var.node_type
  port           = var.port

  # Parameter Group: null이면 AWS 기본값 사용 (Terraform은 null을 속성 미지정으로 처리)
  parameter_group_name = local.effective_parameter_group_name

  # Cluster Mode Disabled (단일 샤드)
  num_node_groups         = 1
  replicas_per_node_group = var.replicas_per_node_group

  # HA 설정
  automatic_failover_enabled = local.effective_automatic_failover
  multi_az_enabled           = local.effective_multi_az

  # 네트워크
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = var.security_group_ids

  # 유지보수
  maintenance_window       = var.maintenance_window
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_retention_limit > 0 ? var.snapshot_window : null

  # 보안 (암호화)
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = var.transit_encryption_enabled ? var.auth_token : null

  # 자동 마이너 버전 업그레이드
  auto_minor_version_upgrade = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cache"
  })

  lifecycle {
    ignore_changes = [
      engine_version # 마이너 버전 자동 업그레이드 시 변경 무시
    ]
  }

  depends_on = [
    aws_elasticache_subnet_group.main
  ]
}

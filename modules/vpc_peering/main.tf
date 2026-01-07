# VPC Peering Module: 메인 리소스
# MGMT VPC와 DEV/STAGE/PROD VPC 간 Peering 연결 생성

# -----------------------------------------------------------------------------
# VPC Peering Connection
# 동일 계정/리전 내에서 auto_accept 가능
# -----------------------------------------------------------------------------
resource "aws_vpc_peering_connection" "main" {
  vpc_id      = var.requester_vpc_id # MGMT VPC
  peer_vpc_id = var.accepter_vpc_id  # Target VPC (DEV/STAGE/PROD)
  auto_accept = true                 # 동일 계정/리전 내 자동 수락

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-peering"
    Environment = var.environment
    Purpose     = "argocd-private-access"
  })
}

# -----------------------------------------------------------------------------
# VPC Peering Connection Options (DNS 해석 활성화)
# Private EKS Endpoint DNS 해석을 위해 필수
# -----------------------------------------------------------------------------
resource "aws_vpc_peering_connection_options" "requester" {
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id

  requester {
    allow_remote_vpc_dns_resolution = var.allow_remote_vpc_dns_resolution
  }
}

resource "aws_vpc_peering_connection_options" "accepter" {
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id

  accepter {
    allow_remote_vpc_dns_resolution = var.allow_remote_vpc_dns_resolution
  }
}

# -----------------------------------------------------------------------------
# Requester VPC Route: MGMT → Target (DEV/STAGE/PROD)
# MGMT의 모든 라우트 테이블에 Target VPC CIDR 경로 추가
# -----------------------------------------------------------------------------
resource "aws_route" "requester_to_accepter" {
  count = length(var.requester_route_table_ids)

  route_table_id            = var.requester_route_table_ids[count.index]
  destination_cidr_block    = var.accepter_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}

# -----------------------------------------------------------------------------
# Accepter VPC Route: Target (DEV/STAGE/PROD) → MGMT
# Target의 모든 라우트 테이블에 MGMT VPC CIDR 경로 추가
# -----------------------------------------------------------------------------
resource "aws_route" "accepter_to_requester" {
  count = length(var.accepter_route_table_ids)

  route_table_id            = var.accepter_route_table_ids[count.index]
  destination_cidr_block    = var.requester_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}

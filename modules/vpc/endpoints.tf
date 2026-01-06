# VPC Endpoints - Phase 3 신규 리소스
# 기존 VPC 모듈에 추가하지 않고 별도 파일로 분리하여 관리
# 기존 리소스 영향 없음

data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# [필수] S3 Gateway Endpoint - 무료, NAT 비용 대폭 절감
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id,
    aws_route_table.public.id
  ]

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-s3-endpoint"
    Purpose = "S3 access without NAT - Phase3"
  })
}

# -----------------------------------------------------------------------------
# [선택] ECR Endpoints - 이미지 pull 시 NAT 비용 절감
# STAGE/PROD 환경에서 권장
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_ecr_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app_private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-ecr-api-endpoint"
    Purpose = "ECR API without NAT - Phase3"
  })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_ecr_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app_private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-ecr-dkr-endpoint"
    Purpose = "ECR DKR without NAT - Phase3"
  })
}

# -----------------------------------------------------------------------------
# [선택] CloudWatch Logs Endpoint - 로그 전송 시 NAT 비용 절감
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "logs" {
  count = var.enable_logs_endpoint ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app_private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-logs-endpoint"
    Purpose = "CloudWatch Logs without NAT - Phase3"
  })
}

# -----------------------------------------------------------------------------
# [선택] STS Endpoint - IRSA 토큰 발급 시 NAT 비용 절감
# PROD 환경에서 권장
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "sts" {
  count = var.enable_sts_endpoint ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app_private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-sts-endpoint"
    Purpose = "STS without NAT - Phase3"
  })
}

# -----------------------------------------------------------------------------
# Endpoint용 Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "vpc_endpoints" {
  count = var.enable_ecr_endpoints || var.enable_logs_endpoint || var.enable_sts_endpoint ? 1 : 0

  name        = "${var.name_prefix}-vpc-endpoints-sg"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc-endpoints-sg"
  })
}

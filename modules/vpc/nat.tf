# VPC Module: NAT Gateway
# VPC당 1개 Regional NAT Gateway (EIP 수동 지정)

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip"
  })

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway (단일, 첫 번째 Public 서브넷에 배치)
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-nat-${local.az_suffixes[0]}"
    Purpose = "internet-traffic"
  })

  depends_on = [aws_internet_gateway.main]
}

# =============================================================================
# 결제 전용 NAT Gateway (PROD 전용)
# PG사 화이트리스트를 위한 고정 EIP 제공
# 인터넷 트래픽과 분리하여 장애 격리
# =============================================================================

# 결제 전용 Elastic IP
resource "aws_eip" "payment" {
  count = var.enable_payment_nat ? 1 : 0

  domain = "vpc"

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-payment-nat-eip"
    Purpose = "payment-gateway"
  })

  depends_on = [aws_internet_gateway.main]
}

# 결제 전용 NAT Gateway (두 번째 AZ에 배치 - 장애 분산)
resource "aws_nat_gateway" "payment" {
  count = var.enable_payment_nat ? 1 : 0

  allocation_id = aws_eip.payment[0].id
  subnet_id     = length(aws_subnet.public) > 1 ? aws_subnet.public[1].id : aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-payment-nat"
    Purpose = "payment-gateway-only"
  })

  depends_on = [aws_internet_gateway.main]
}

# 결제 전용 Route Table
resource "aws_route_table" "payment" {
  count = var.enable_payment_nat ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-payment-rt"
    Purpose = "payment-gateway-routing"
  })
}

# 결제 전용 Route (NAT Gateway 경유)
resource "aws_route" "payment_nat" {
  count = var.enable_payment_nat ? 1 : 0

  route_table_id         = aws_route_table.payment[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.payment[0].id
}

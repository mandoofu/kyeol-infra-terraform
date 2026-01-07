# EKS Module: Managed Node Group

# -----------------------------------------------------------------------------
# Node Group IAM Role
# -----------------------------------------------------------------------------
resource "aws_iam_role" "node_group" {
  name = "${var.name_prefix}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-node-role"
  })
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# SSM 접근 (선택적이지만 디버깅에 유용)
resource "aws_iam_role_policy_attachment" "node_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node_group.name
}

# -----------------------------------------------------------------------------
# Managed Node Group (일반 워크로드)
# -----------------------------------------------------------------------------
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.name_prefix}-${var.node_group_name}"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.subnet_ids

  instance_types = var.node_instance_types
  capacity_type  = var.node_capacity_type
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    Environment = var.environment
    NodeGroup   = var.node_group_name
    node-type   = "general"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-node"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# -----------------------------------------------------------------------------
# Payment Node Group (결제 전용 워크로드)
# Payment Subnet에 배치, 결제 NAT Gateway 사용
# -----------------------------------------------------------------------------
resource "aws_eks_node_group" "payment" {
  count = var.enable_payment_node_group ? 1 : 0

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.name_prefix}-payment"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.payment_subnet_ids

  instance_types = var.payment_node_instance_types
  capacity_type  = "ON_DEMAND" # 결제는 안정성 우선
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.payment_node_desired_size
    min_size     = var.payment_node_min_size
    max_size     = var.payment_node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    Environment = var.environment
    NodeGroup   = "payment"
    node-type   = "payment"
    purpose     = "payment-gateway"
  }

  # Taint: 결제 Pod만 스케줄링 허용
  taint {
    key    = "payment"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-eks-payment-node"
    Purpose = "payment-gateway"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

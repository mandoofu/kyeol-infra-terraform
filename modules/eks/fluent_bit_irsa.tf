# Fluent Bit IRSA - Phase 3 신규 파일
# EKS 모듈에 추가되는 Fluent Bit 전용 IRSA 설정
# Node IAM 권한 사용 금지 - IRSA 필수

# -----------------------------------------------------------------------------
# Fluent Bit 전용 IAM Role (IRSA)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "fluent_bit" {
  count = var.enable_fluent_bit_irsa ? 1 : 0

  name = "${var.name_prefix}-fluent-bit-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.cluster[0].arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:amazon-cloudwatch:fluent-bit"
        }
      }
    }]
  })

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-fluent-bit-role"
    Purpose = "Fluent Bit IRSA"
    Phase   = "3"
  })
}

# -----------------------------------------------------------------------------
# Fluent Bit 최소 권한 IAM Policy
# CloudWatch Logs 관련 권한만 부여
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "fluent_bit" {
  count = var.enable_fluent_bit_irsa ? 1 : 0

  name = "${var.name_prefix}-fluent-bit-policy"
  role = aws_iam_role.fluent_bit[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = [
        "arn:aws:logs:*:*:log-group:/aws/eks/${var.cluster_name}/*",
        "arn:aws:logs:*:*:log-group:/aws/containerinsights/${var.cluster_name}/*"
      ]
    }]
  })
}

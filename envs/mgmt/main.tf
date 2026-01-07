# MGMT Environment: 메인 모듈 구성
# Phase-1 적용 대상 (CI/CD 전용 클러스터)

locals {
  name_prefix  = "${var.owner_prefix}-${var.project_name}-${var.environment}"
  cluster_name = "${local.name_prefix}-eks"

  # MGMT CIDR 설정 (spec.md 기준)
  public_subnet_cidrs      = ["10.40.0.0/24", "10.40.1.0/24"]  # 2 AZ
  app_private_subnet_cidrs = ["10.40.4.0/22", "10.40.12.0/22"] # 2 AZ (ops-private)
  # MGMT에는 data/cache subnet 없음 (ArgoCD/모니터링 전용)

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner_prefix
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# VPC Module
# -----------------------------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  name_prefix = local.name_prefix
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  azs         = var.azs

  public_subnet_cidrs        = local.public_subnet_cidrs
  app_private_subnet_cidrs   = local.app_private_subnet_cidrs
  data_private_subnet_cidrs  = [] # MGMT는 data subnet 없음
  cache_private_subnet_cidrs = [] # MGMT는 cache 없음

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_vpc_endpoints = true

  eks_cluster_name = local.cluster_name

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# EKS Module
# -----------------------------------------------------------------------------
module "eks" {
  source = "../../modules/eks"

  name_prefix     = local.name_prefix
  environment     = var.environment
  cluster_name    = local.cluster_name
  cluster_version = var.eks_cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.app_private_subnet_ids

  # Node Group
  node_instance_types = var.eks_node_instance_types
  node_desired_size   = var.eks_node_desired_size
  node_min_size       = var.eks_node_min_size
  node_max_size       = var.eks_node_max_size

  # IRSA (MGMT에서도 ALB Controller/ExternalDNS 사용 가능)
  enable_irsa                 = true
  enable_alb_controller_irsa  = true
  enable_external_dns_irsa    = true
  external_dns_hosted_zone_id = var.hosted_zone_id

  tags = local.common_tags
}

# Note: MGMT 환경에는 RDS/Cache 없음 (ArgoCD/모니터링 전용)

# =============================================================================
# Phase 3: Global WAF (CloudFront용, us-east-1)
# 모든 환경(DEV/STAGE/PROD)이 이 WAF를 공유
# =============================================================================

# WAF 로그용 S3 버킷 (us-east-1에 생성 필요)
resource "aws_s3_bucket" "waf_logs" {
  count    = var.enable_global_waf && var.enable_waf_logging ? 1 : 0
  provider = aws.virginia

  bucket = "aws-waf-logs-${var.owner_prefix}-${var.project_name}-global"

  tags = merge(local.common_tags, {
    Name    = "aws-waf-logs-${var.owner_prefix}-${var.project_name}-global"
    Purpose = "waf-log-storage"
    Phase   = "3"
    Region  = "us-east-1"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "waf_logs" {
  count    = var.enable_global_waf && var.enable_waf_logging ? 1 : 0
  provider = aws.virginia
  bucket   = aws_s3_bucket.waf_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  count    = var.enable_global_waf && var.enable_waf_logging ? 1 : 0
  provider = aws.virginia
  bucket   = aws_s3_bucket.waf_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "waf_logs" {
  count    = var.enable_global_waf && var.enable_waf_logging ? 1 : 0
  provider = aws.virginia
  bucket   = aws_s3_bucket.waf_logs[0].id

  rule {
    id     = "expire-waf-logs"
    status = "Enabled"

    filter {}

    # ISMS-P 2.10.1: 보안 로그 최소 1년 보관
    expiration {
      days = 365
    }

    # 90일 후 Glacier로 전환 (비용 절감)
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

module "waf_global" {
  source = "../../modules/waf_global"
  count  = var.enable_global_waf ? 1 : 0

  providers = {
    aws = aws.virginia
  }

  name_prefix         = "${var.owner_prefix}-${var.project_name}"
  rate_limit          = var.waf_rate_limit
  enable_logging      = var.enable_waf_logging
  waf_logs_bucket_arn = var.enable_waf_logging ? aws_s3_bucket.waf_logs[0].arn : ""

  tags = local.common_tags

  depends_on = [
    aws_s3_bucket.waf_logs,
    aws_s3_bucket_public_access_block.waf_logs
  ]
}

# =============================================================================
# Phase 3: CloudFront (PROD용 - 단일 배포)
# origin-prod.domain으로 요청 라우팅
# =============================================================================
module "cloudfront" {
  source = "../../modules/cloudfront"
  count  = var.enable_cloudfront ? 1 : 0

  providers = {
    aws = aws.virginia
  }

  name_prefix         = "${var.owner_prefix}-${var.project_name}"
  environment         = "prod" # CloudFront는 PROD 대표
  domain              = var.domain
  domain_aliases      = [var.domain, "www.${var.domain}"]
  origin_domain       = "origin-prod.${var.domain}"
  acm_certificate_arn = var.cloudfront_acm_arn
  waf_global_arn      = var.enable_global_waf ? module.waf_global[0].web_acl_arn : ""
  price_class         = "PriceClass_All"

  tags = local.common_tags
}

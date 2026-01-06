# DEV Environment: 메인 모듈 구성
# Phase-1 적용 대상

locals {
  name_prefix  = "${var.owner_prefix}-${var.project_name}-${var.environment}"
  cluster_name = "${local.name_prefix}-eks"

  # DEV CIDR 설정 (AWS EKS/RDS는 최소 2개 AZ 서브넷 필요)
  # spec.md 기준에서 AWS 제약 충족을 위해 2번째 AZ 추가
  public_subnet_cidrs       = ["10.10.0.0/24", "10.10.1.0/24"]  # 2 AZ (a, c)
  app_private_subnet_cidrs  = ["10.10.4.0/23", "10.10.6.0/23"]  # 2 AZ (a, c) - EKS 요구사항
  data_private_subnet_cidrs = ["10.10.9.0/24", "10.10.10.0/24"] # 2 AZ (a, c) - RDS 서브넷 그룹 요구사항
  # DEV에는 cache subnet 없음

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
  data_private_subnet_cidrs  = local.data_private_subnet_cidrs
  cache_private_subnet_cidrs = [] # DEV는 cache 없음

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_vpc_endpoints = true

  # Phase 3: VPC Endpoints
  enable_s3_endpoint   = var.enable_s3_endpoint
  enable_ecr_endpoints = var.enable_ecr_endpoints
  enable_logs_endpoint = var.enable_logs_endpoint

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

  # IRSA
  enable_irsa                 = true
  enable_alb_controller_irsa  = true
  enable_external_dns_irsa    = true
  external_dns_hosted_zone_id = var.hosted_zone_id

  # Phase 3: Fluent Bit IRSA
  enable_fluent_bit_irsa = var.enable_fluent_bit_irsa

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# RDS PostgreSQL Module
# -----------------------------------------------------------------------------
module "rds" {
  source = "../../modules/rds_postgres"

  name_prefix = local.name_prefix
  environment = var.environment

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.data_private_subnet_ids
  security_group_ids = module.vpc.rds_security_group_id != null ? [module.vpc.rds_security_group_id] : []

  instance_class = var.rds_instance_class
  multi_az       = var.rds_multi_az

  # DEV 설정
  deletion_protection = false
  skip_final_snapshot = true

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ECR Module
# -----------------------------------------------------------------------------
module "ecr" {
  source = "../../modules/ecr"

  name_prefix = "${var.owner_prefix}-${var.project_name}"

  repository_names = ["api", "storefront", "dashboard"]

  tags = local.common_tags
}

# =============================================================================
# Phase 3: 보안 & 모니터링 모듈
# =============================================================================

# -----------------------------------------------------------------------------
# S3 Module (미디어 + 로그 버킷)
# -----------------------------------------------------------------------------
module "s3_phase3" {
  source = "../../modules/s3"
  count  = var.enable_phase3_s3 ? 1 : 0

  name_prefix            = local.name_prefix
  environment            = var.environment
  create_media_bucket    = true
  create_logs_bucket     = true
  create_waf_logs_bucket = false  # WAF 로그는 MGMT에서 중앙 관리
  logs_retention_days    = var.logs_retention_days

  tags = local.common_tags
}


# -----------------------------------------------------------------------------
# Origin 도메인 Route53 레코드 (CloudFront용)
# -----------------------------------------------------------------------------
resource "aws_route53_record" "origin" {
  count = var.enable_cloudfront && var.cloudfront_origin_alb_dns != "" ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = "origin-${var.environment}.${var.domain}"
  type    = "A"

  alias {
    name                   = var.cloudfront_origin_alb_dns
    zone_id                = var.cloudfront_origin_alb_zone_id
    evaluate_target_health = true
  }
}


# -----------------------------------------------------------------------------
# CloudTrail Module (P0: 계정당 1개 권장)
# DEV에서는 기본 OFF - prod에서만 활성화 권장
# -----------------------------------------------------------------------------
module "cloudtrail" {
  source = "../../modules/cloudtrail"
  count  = var.enable_cloudtrail ? 1 : 0

  name_prefix    = local.name_prefix
  environment    = var.environment
  aws_account_id = var.aws_account_id

  enable_cloudtrail      = true
  enable_data_events     = var.enable_cloudtrail_data_events
  enable_cloudwatch_logs = var.enable_cloudtrail_cloudwatch

  # KMS는 DEV에서 비활성화, STAGE/PROD는 tfvars에서 설정
  enable_kms_encryption = false

  tags = local.common_tags
}

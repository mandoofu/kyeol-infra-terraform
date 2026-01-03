# PROD Environment: 메인 모듈 구성
# Phase-2 적용 대상 - Production Grade

locals {
  name_prefix  = "${var.owner_prefix}-${var.project_name}-${var.environment}"
  cluster_name = "${local.name_prefix}-eks"

  # PROD CIDR 설정 (spec.md 기준 - 3 AZ)
  public_subnet_cidrs        = ["10.30.0.0/24", "10.30.1.0/24", "10.30.2.0/24"]    # 3 AZ
  app_private_subnet_cidrs   = ["10.30.4.0/22", "10.30.8.0/22", "10.30.12.0/22"]   # 3 AZ
  data_private_subnet_cidrs  = ["10.30.16.0/24", "10.30.17.0/24", "10.30.18.0/24"] # 3 AZ
  cache_private_subnet_cidrs = ["10.30.24.0/24", "10.30.25.0/24", "10.30.26.0/24"] # 3 AZ

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner_prefix
    ManagedBy   = "terraform"
    CostCenter  = "production"
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
  cache_private_subnet_cidrs = var.enable_cache ? local.cache_private_subnet_cidrs : []

  enable_nat_gateway   = true
  single_nat_gateway   = false # PROD: AZ별 NAT Gateway
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

  # Node Group (PROD: 프로덕션급)
  node_instance_types = var.eks_node_instance_types
  node_desired_size   = var.eks_node_desired_size
  node_min_size       = var.eks_node_min_size
  node_max_size       = var.eks_node_max_size

  # IRSA
  enable_irsa                 = true
  enable_alb_controller_irsa  = true
  enable_external_dns_irsa    = true
  external_dns_hosted_zone_id = var.hosted_zone_id

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

  instance_class          = var.rds_instance_class
  multi_az                = var.rds_multi_az
  allocated_storage       = var.rds_allocated_storage
  backup_retention_period = var.rds_backup_retention_period

  # PROD 설정
  deletion_protection = var.rds_deletion_protection
  skip_final_snapshot = false

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Valkey (ElastiCache) Module - PROD: 고성능 HA 클러스터
# -----------------------------------------------------------------------------
module "valkey" {
  count  = var.enable_cache ? 1 : 0
  source = "../../modules/valkey"

  name_prefix = local.name_prefix
  environment = var.environment

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.cache_private_subnet_ids
  security_group_ids = module.vpc.cache_security_group_id != null ? [module.vpc.cache_security_group_id] : []

  node_type = var.cache_node_type

  # PROD: HA 설정 (1 replica)
  replicas_per_node_group    = var.cache_num_nodes > 1 ? var.cache_num_nodes - 1 : 1
  automatic_failover_enabled = true
  multi_az_enabled           = true

  # PROD: 스냅샷 보존
  snapshot_retention_limit = 7

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ECR Module (환경별 고유 이름으로 충돌 방지)
# -----------------------------------------------------------------------------
module "ecr" {
  source = "../../modules/ecr"

  # PROD 전용 ECR: min-kyeol-prod-api 등으로 생성
  name_prefix = "${var.owner_prefix}-${var.project_name}-${var.environment}"

  repository_names = ["api", "storefront", "dashboard"]

  scan_on_push = true # PROD: 이미지 스캔 활성화

  tags = local.common_tags
}

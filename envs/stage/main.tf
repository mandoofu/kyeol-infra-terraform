# STAGE Environment: 메인 모듈 구성
# Phase-2 적용 대상

locals {
  name_prefix  = "${var.owner_prefix}-${var.project_name}-${var.environment}"
  cluster_name = "${local.name_prefix}-eks"

  # STAGE CIDR 설정 (spec.md 기준)
  public_subnet_cidrs        = ["10.20.0.0/24", "10.20.1.0/24"]   # 2 AZ (a, c)
  app_private_subnet_cidrs   = ["10.20.4.0/22", "10.20.8.0/22"]   # 2 AZ (a, c)
  data_private_subnet_cidrs  = ["10.20.16.0/24", "10.20.17.0/24"] # 2 AZ (a, c)
  cache_private_subnet_cidrs = ["10.20.24.0/24", "10.20.25.0/24"] # 2 AZ (a, c)

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
  cache_private_subnet_cidrs = var.enable_cache ? local.cache_private_subnet_cidrs : []

  enable_nat_gateway   = true
  single_nat_gateway   = false # STAGE: 2개 NAT Gateway
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

  # Node Group (STAGE: DEV보다 상향)
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

  instance_class    = var.rds_instance_class
  multi_az          = var.rds_multi_az
  allocated_storage = var.rds_allocated_storage

  # STAGE 설정
  deletion_protection = false
  skip_final_snapshot = true

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Valkey (ElastiCache) Module - STAGE: HA 활성화
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

  # STAGE: HA 설정 (1 replica)
  replicas_per_node_group    = 1
  automatic_failover_enabled = true
  multi_az_enabled           = true

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ECR Module (환경별 고유 이름으로 충돌 방지)
# -----------------------------------------------------------------------------
module "ecr" {
  source = "../../modules/ecr"

  # STAGE 전용 ECR: min-kyeol-stage-api 등으로 생성
  name_prefix = "${var.owner_prefix}-${var.project_name}-${var.environment}"

  repository_names = ["api", "storefront", "dashboard"]

  tags = local.common_tags
}

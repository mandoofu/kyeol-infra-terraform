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

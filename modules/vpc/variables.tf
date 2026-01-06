# VPC Module: 변수 정의

variable "name_prefix" {
  description = "리소스 이름 프리픽스 (예: min-kyeol-dev)"
  type        = string
}

variable "environment" {
  description = "환경 이름 (dev, stage, prod, mgmt)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
}

variable "azs" {
  description = "사용할 가용영역 목록 (예: [\"ap-southeast-2a\", \"ap-southeast-2c\"])"
  type        = list(string)
}

# Subnet CIDRs
variable "public_subnet_cidrs" {
  description = "Public 서브넷 CIDR 목록 (AZ 순서대로)"
  type        = list(string)
}

variable "app_private_subnet_cidrs" {
  description = "App Private 서브넷 CIDR 목록 (AZ 순서대로)"
  type        = list(string)
}

variable "data_private_subnet_cidrs" {
  description = "Data Private 서브넷 CIDR 목록 (AZ 순서대로)"
  type        = list(string)
  default     = []
}

variable "cache_private_subnet_cidrs" {
  description = "Cache Private 서브넷 CIDR 목록 (AZ 순서대로, DEV는 빈 배열)"
  type        = list(string)
  default     = []
}

# NAT Gateway 설정
variable "enable_nat_gateway" {
  description = "NAT Gateway 생성 여부"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "단일 NAT Gateway 사용 여부 (true = VPC당 1개, false = AZ당 1개)"
  type        = bool
  default     = true
}

# VPC Endpoints
variable "enable_vpc_endpoints" {
  description = "VPC Endpoints(S3, ECR 등) 생성 여부"
  type        = bool
  default     = true
}

# 결제 전용 NAT Gateway (PROD 전용)
variable "enable_payment_nat" {
  description = "결제 전용 NAT Gateway 생성 (PG사 화이트리스트용 고정 EIP)"
  type        = bool
  default     = false
}

variable "payment_subnet_cidrs" {
  description = "결제 전용 서브넷 CIDR 목록 (결제 Pod가 배치될 서브넷)"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}

# EKS 클러스터 이름 (서브넷 태그용)
variable "eks_cluster_name" {
  description = "EKS 클러스터 이름 (서브넷 태그에 사용)"
  type        = string
  default     = ""
}

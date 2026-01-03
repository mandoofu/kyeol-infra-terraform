# STAGE Environment Variables

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_account_id" {
  description = "AWS 계정 ID"
  type        = string
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "kyeol"
}

variable "owner_prefix" {
  description = "소유자 프리픽스"
  type        = string
  default     = "min"
}

variable "environment" {
  description = "환경 이름"
  type        = string
  default     = "stage"
}

# VPC
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.20.0.0/16"
}

variable "azs" {
  description = "가용영역 목록"
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2c"]
}

# EKS
variable "eks_cluster_version" {
  description = "EKS 클러스터 버전"
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "EKS 노드 인스턴스 타입"
  type        = list(string)
  default     = ["t3.large"]
}

variable "eks_node_desired_size" {
  description = "EKS 노드 희망 수"
  type        = number
  default     = 3
}

variable "eks_node_min_size" {
  description = "EKS 노드 최소 수"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "EKS 노드 최대 수"
  type        = number
  default     = 5
}

# RDS
variable "rds_instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t3.medium"
}

variable "rds_multi_az" {
  description = "RDS Multi-AZ 활성화"
  type        = bool
  default     = true
}

variable "rds_allocated_storage" {
  description = "RDS 할당 스토리지 (GB)"
  type        = number
  default     = 50
}

# Route53
variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID (msp-g1.click)"
  type        = string
}

# Cache (Valkey)
variable "enable_cache" {
  description = "Valkey 캐시 활성화"
  type        = bool
  default     = true
}

variable "cache_node_type" {
  description = "캐시 노드 타입"
  type        = string
  default     = "cache.t3.small"
}

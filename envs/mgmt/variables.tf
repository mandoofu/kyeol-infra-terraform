# MGMT Environment: 변수 정의

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
  default     = "mgmt"
}

# VPC 설정
variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.40.0.0/16"
}

variable "azs" {
  description = "가용영역 목록"
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2c"]
}

# EKS 설정
variable "eks_cluster_version" {
  description = "EKS 클러스터 버전"
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "EKS 노드 인스턴스 타입"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_size" {
  description = "EKS 노드 희망 크기"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "EKS 노드 최소 크기"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "EKS 노드 최대 크기"
  type        = number
  default     = 3
}

# Route53
variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID (msp-g1.click)"
  type        = string
  default     = ""
}

# =============================================================================
# Phase 3: Global WAF + CloudFront (MGMT에서 생성, 모든 환경 공유)
# =============================================================================

variable "enable_global_waf" {
  description = "Global WAF 생성 (CloudFront용, us-east-1)"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "WAF Rate Limit (5분당 요청 수)"
  type        = number
  default     = 5000
}

variable "enable_waf_logging" {
  description = "WAF 로그를 S3에 저장 (us-east-1에 버킷 생성)"
  type        = bool
  default     = false
}

variable "enable_cloudfront" {
  description = "CloudFront 생성"
  type        = bool
  default     = false
}

variable "cloudfront_acm_arn" {
  description = "CloudFront용 ACM 인증서 ARN (us-east-1)"
  type        = string
  default     = ""
}

variable "domain" {
  description = "기본 도메인 (예: msp-g1.click)"
  type        = string
  default     = "msp-g1.click"
}

# Origin 도메인 (환경별)
variable "origin_domain_dev" {
  description = "DEV Origin 도메인 (origin-dev.domain)"
  type        = string
  default     = ""
}

variable "origin_domain_stage" {
  description = "STAGE Origin 도메인 (origin-stage.domain)"
  type        = string
  default     = ""
}

variable "origin_domain_prod" {
  description = "PROD Origin 도메인 (origin-prod.domain)"
  type        = string
  default     = ""
}

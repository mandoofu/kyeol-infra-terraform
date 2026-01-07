# EKS Module: 변수 정의

variable "name_prefix" {
  description = "리소스 이름 프리픽스 (예: min-kyeol-dev)"
  type        = string
}

variable "environment" {
  description = "환경 이름 (dev, stage, prod, mgmt)"
  type        = string
}

variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
}

variable "cluster_version" {
  description = "EKS 클러스터 Kubernetes 버전 (Standard Support 버전만 사용 - Extended Support 과금 방지)"
  type        = string
  default     = "1.32" # Standard Support: ~2026-03-23

  # Extended Support 사용 방지 가드
  # 1.29 이하: Extended Support 진입 (시간당 $0.60 과금)
  # 1.31, 1.32: Standard Support (추가 과금 없음)
  validation {
    condition     = tonumber(split(".", var.cluster_version)[1]) >= 31
    error_message = "EKS 버전 1.31 이상만 허용됩니다. 1.30 이하는 Extended Support로 시간당 $0.60 과금됩니다."
  }
}

# 네트워크
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "EKS 노드가 실행될 서브넷 ID 목록"
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "EKS 컨트롤 플레인 서브넷 ID 목록 (비워두면 subnet_ids 사용)"
  type        = list(string)
  default     = []
}

# Node Group
variable "node_group_name" {
  description = "노드 그룹 이름"
  type        = string
  default     = "default"
}

variable "node_instance_types" {
  description = "노드 인스턴스 타입 목록"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "노드 그룹 희망 크기"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "노드 그룹 최소 크기"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "노드 그룹 최대 크기"
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "노드 EBS 볼륨 크기 (GB)"
  type        = number
  default     = 50
}

variable "node_capacity_type" {
  description = "노드 용량 타입 (ON_DEMAND 또는 SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

# IRSA 설정
variable "enable_irsa" {
  description = "IRSA(IAM Roles for Service Accounts) 활성화 여부"
  type        = bool
  default     = true
}

# AWS Load Balancer Controller IRSA
variable "enable_alb_controller_irsa" {
  description = "AWS Load Balancer Controller IRSA 생성 여부"
  type        = bool
  default     = true
}

# ExternalDNS IRSA
variable "enable_external_dns_irsa" {
  description = "ExternalDNS IRSA 생성 여부"
  type        = bool
  default     = true
}

variable "external_dns_hosted_zone_id" {
  description = "ExternalDNS가 관리할 Route53 Hosted Zone ID"
  type        = string
  default     = ""
}

# =============================================================================
# CloudWatch Logs 설정 (ISMS-P 기준)
# =============================================================================
# 로그 수집 정책:
#   - DEV/STAGE: 기본 비활성화 (비용 절감)
#   - PROD: audit 로그만 활성화 (ISMS-P 필수 + 비용 최적화)
#   - MGMT: authenticator 추가 (관리 클러스터 보안)
#
# 로그 타입별 용도:
#   - api: API 서버 요청/응답 로그 (디버깅용, 비용 높음)
#   - audit: 감사 로그 (ISMS-P 필수, 접근 기록)
#   - authenticator: 인증 로그 (보안 분석용)
#   - controllerManager: 컨트롤러 로그 (장애 분석용)
#   - scheduler: 스케줄러 로그 (장애 분석용)
# =============================================================================
variable "enabled_cluster_log_types" {
  description = "활성화할 EKS 클러스터 로그 타입 (비용 주의: 저장/수집 과금)"
  type        = list(string)
  default     = [] # 기본 비활성화 (비용 방지)

  validation {
    condition = alltrue([
      for log_type in var.enabled_cluster_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "유효한 로그 타입: api, audit, authenticator, controllerManager, scheduler"
  }
}

variable "endpoint_private_access" {
  description = "EKS API 엔드포인트 Private 접근 허용"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "EKS API 엔드포인트 Public 접근 허용"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "EKS Public 엔드포인트 접근 허용 CIDR"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# =============================================================================
# Private Endpoint 접근 설정 (VPC Peering용)
# =============================================================================
variable "mgmt_vpc_cidrs" {
  description = "MGMT VPC CIDR 목록 (ArgoCD가 EKS Private Endpoint에 접근 허용)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}

# =============================================================================
# Payment Node Group (결제 전용 - PROD 전용)
# =============================================================================
variable "enable_payment_node_group" {
  description = "결제 전용 Node Group 생성 여부"
  type        = bool
  default     = false
}

variable "payment_subnet_ids" {
  description = "결제 Node Group이 배치될 서브넷 ID 목록"
  type        = list(string)
  default     = []
}

variable "payment_node_instance_types" {
  description = "결제 노드 인스턴스 타입"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "payment_node_desired_size" {
  description = "결제 노드 희망 크기"
  type        = number
  default     = 1
}

variable "payment_node_min_size" {
  description = "결제 노드 최소 크기"
  type        = number
  default     = 1
}

variable "payment_node_max_size" {
  description = "결제 노드 최대 크기"
  type        = number
  default     = 2
}

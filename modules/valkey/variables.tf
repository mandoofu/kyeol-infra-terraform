# Valkey/Redis (ElastiCache) Module: 변수 정의
# Replication Group 기반으로 Stage/Prod HA 지원

variable "name_prefix" {
  description = "리소스 이름 프리픽스 (예: min-kyeol-dev)"
  type        = string
}

variable "environment" {
  description = "환경 이름 (dev, stage, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "ElastiCache가 배치될 서브넷 ID 목록"
  type        = list(string)
}

variable "security_group_ids" {
  description = "ElastiCache에 적용할 보안 그룹 ID 목록"
  type        = list(string)
}

# Cache 엔진 설정
variable "engine" {
  description = "캐시 엔진 (valkey 또는 redis)"
  type        = string
  default     = "valkey"
}

variable "engine_version" {
  description = "엔진 버전"
  type        = string
  default     = "7.2"
}

variable "node_type" {
  description = "노드 타입"
  type        = string
  default     = "cache.t3.micro"

  validation {
    # r6g, r6gd 계열은 medium 불가 (large 이상만 지원)
    # t3, t4g 계열은 모든 크기 허용
    condition = (
      !can(regex("^cache\\.(r6g|r6gd|r5|r4)\\.medium$", var.node_type))
    )
    error_message = "Valkey/ElastiCache에서 r6g.medium은 지원되지 않습니다. r6g.large 이상 또는 t3/t4g 계열을 사용하세요."
  }
}

variable "port" {
  description = "포트 번호"
  type        = number
  default     = 6379
}

# Parameter Group 설정
variable "parameter_group_name" {
  description = "사용할 Parameter Group 이름 (null이면 AWS 기본값 사용)"
  type        = string
  default     = null
}

variable "create_parameter_group" {
  description = "커스텀 Parameter Group 생성 여부"
  type        = bool
  default     = false
}

variable "parameter_group_family" {
  description = "Parameter Group family (create_parameter_group=true일 때 필수, 예: valkey7)"
  type        = string
  default     = null
}

variable "parameter_group_parameters" {
  description = "커스텀 Parameter Group 파라미터 목록"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# HA 설정 (Replication Group 전용)
variable "replicas_per_node_group" {
  description = "노드 그룹당 Replica 수 (0=단일 노드, 1+=HA). DEV=0, Stage/Prod>=1 권장"
  type        = number
  default     = 0

  validation {
    condition     = var.replicas_per_node_group >= 0 && var.replicas_per_node_group <= 5
    error_message = "replicas_per_node_group은 0~5 사이여야 합니다."
  }
}

variable "automatic_failover_enabled" {
  description = "자동 Failover 활성화 (replicas >= 1일 때만 가능)"
  type        = bool
  default     = false
}

variable "multi_az_enabled" {
  description = "Multi-AZ 활성화 (replicas >= 1일 때만 가능)"
  type        = bool
  default     = false
}

# 유지보수
variable "maintenance_window" {
  description = "유지보수 윈도우"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "snapshot_retention_limit" {
  description = "스냅샷 보존 기간 (일, 0=비활성화)"
  type        = number
  default     = 0
}

variable "snapshot_window" {
  description = "스냅샷 윈도우"
  type        = string
  default     = "03:00-04:00"
}

# 보안
variable "at_rest_encryption_enabled" {
  description = "저장 시 암호화 활성화"
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "전송 중 암호화 활성화"
  type        = bool
  default     = false
}

variable "auth_token" {
  description = "AUTH 토큰 (transit encryption 활성 시 필요, 16~128자)"
  type        = string
  default     = null
  sensitive   = true
}

variable "tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}

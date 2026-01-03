# RDS PostgreSQL Module: 변수 정의

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
  description = "RDS가 배치될 서브넷 ID 목록 (최소 2개 AZ)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "RDS에 적용할 보안 그룹 ID 목록"
  type        = list(string)
}

# Database 설정
variable "db_name" {
  description = "초기 데이터베이스 이름"
  type        = string
  default     = "saleor"
}

variable "db_username" {
  description = "마스터 사용자 이름"
  type        = string
  default     = "saleor_admin"
}

variable "engine_version" {
  description = "PostgreSQL 엔진 버전"
  type        = string
  default     = "16" # ap-southeast-2에서 사용 가능한 버전
}

variable "instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t3.small"
}

variable "allocated_storage" {
  description = "할당 스토리지 (GB)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "최대 할당 스토리지 (GB, autoscaling)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "스토리지 타입"
  type        = string
  default     = "gp3"
}

# 가용성
variable "multi_az" {
  description = "Multi-AZ 배포 여부"
  type        = bool
  default     = false
}

# 백업
variable "backup_retention_period" {
  description = "백업 보존 기간 (일)"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "백업 윈도우 (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "유지보수 윈도우 (UTC)"
  type        = string
  default     = "Mon:04:00-Mon:05:00"
}

# 보안
variable "deletion_protection" {
  description = "삭제 보호 활성화"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "삭제 시 최종 스냅샷 생략"
  type        = bool
  default     = true
}

variable "storage_encrypted" {
  description = "스토리지 암호화 활성화"
  type        = bool
  default     = true
}

variable "tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}

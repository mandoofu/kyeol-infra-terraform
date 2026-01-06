# S3 Module - Phase 3 신규 모듈
# 미디어 및 로그 저장용 S3 버킷 (보안 기본값 강제)

variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "environment" {
  description = "환경 (dev/stage/prod)"
  type        = string
}

variable "create_media_bucket" {
  description = "미디어 버킷 생성 여부"
  type        = bool
  default     = true
}

variable "create_logs_bucket" {
  description = "로그 버킷 생성 여부"
  type        = bool
  default     = true
}

variable "create_waf_logs_bucket" {
  description = "WAF 로그 버킷 생성 여부 (MGMT에서만 true)"
  type        = bool
  default     = false
}

variable "logs_retention_days" {
  description = "로그 보존 기간 (일) - DEV:14 / STAGE:30 / PROD:90"
  type        = number
  default     = 90
}

# KMS 암호화 옵션 (P0: STAGE/PROD 권장)
variable "enable_kms_encryption" {
  description = "KMS(SSE-KMS) 암호화 활성화 - STAGE/PROD 권장"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS 키 ARN (enable_kms_encryption=true일 때 필요)"
  type        = string
  default     = ""
}

# TLS 강제 (P0: 필수)
variable "enforce_tls" {
  description = "TLS(HTTPS) 전송 강제 - 비활성화 금지"
  type        = bool
  default     = true
}

# Glacier 장기 보관 (P1: PROD 권장)
variable "enable_glacier_transition" {
  description = "Glacier 장기 보관 전환 활성화"
  type        = bool
  default     = false
}

variable "glacier_transition_days" {
  description = "Glacier 전환 일수"
  type        = number
  default     = 90
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

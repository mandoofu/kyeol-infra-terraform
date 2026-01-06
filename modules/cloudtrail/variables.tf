# CloudTrail Module - Phase 3
# 계정 레벨 감사 로그 수집

variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "environment" {
  description = "환경 (dev/stage/prod)"
  type        = string
}

variable "aws_account_id" {
  description = "AWS 계정 ID"
  type        = string
}

# CloudTrail 활성화
variable "enable_cloudtrail" {
  description = "CloudTrail 활성화 - 계정당 1개만 권장 (prod 또는 mgmt에서만 true)"
  type        = bool
  default     = false
}

# 데이터 이벤트 (비용 주의)
variable "enable_data_events" {
  description = "S3/Lambda 데이터 이벤트 로깅 - 비용 발생 주의 (STAGE/PROD 권장)"
  type        = bool
  default     = false
}

# KMS 암호화
variable "enable_kms_encryption" {
  description = "KMS 암호화 활성화 - STAGE/PROD 권장"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS 키 ARN (enable_kms_encryption=true일 때 필요)"
  type        = string
  default     = ""
}

# CloudWatch Logs 연동 (비용 주의)
variable "enable_cloudwatch_logs" {
  description = "CloudWatch Logs 연동 - 비용 발생 주의 (실시간 알람 필요 시만)"
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_retention" {
  description = "CloudWatch Logs 보존 기간 (일)"
  type        = number
  default     = 30
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

# VPC Endpoints 관련 변수 - Phase 3 추가
# 기존 variables.tf에 추가되는 신규 변수들
# 기본값은 false로 설정하여 기존 환경에 영향 없음

variable "enable_s3_endpoint" {
  description = "S3 Gateway VPC Endpoint 생성 여부 (권장: true)"
  type        = bool
  default     = false
}

variable "enable_ecr_endpoints" {
  description = "ECR API/DKR Interface VPC Endpoints 생성 여부 (STAGE/PROD 권장)"
  type        = bool
  default     = false
}

variable "enable_logs_endpoint" {
  description = "CloudWatch Logs Interface VPC Endpoint 생성 여부 (STAGE/PROD 권장)"
  type        = bool
  default     = false
}

variable "enable_sts_endpoint" {
  description = "STS Interface VPC Endpoint 생성 여부 (PROD 권장)"
  type        = bool
  default     = false
}

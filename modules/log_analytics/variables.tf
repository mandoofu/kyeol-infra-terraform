# =============================================================================
# Log Analytics Module: 변수 정의
# ISMS-P 기준 로그 모니터링 자동화 파이프라인
# =============================================================================

variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "environment" {
  description = "환경 (mgmt)"
  type        = string
  default     = "mgmt"
}

variable "aws_account_id" {
  description = "AWS 계정 ID"
  type        = string
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-southeast-2"
}

# =============================================================================
# S3 버킷 설정
# =============================================================================
variable "audit_bucket_name" {
  description = "CloudTrail 감사 로그 S3 버킷 이름"
  type        = string
}

variable "report_bucket_name" {
  description = "리포트 저장 S3 버킷 이름 (자동 생성)"
  type        = string
  default     = ""
}

# =============================================================================
# ISMS-P 준수 설정
# =============================================================================
variable "log_retention_days" {
  description = "로그 보존 기간 (ISMS-P: 최소 1년)"
  type        = number
  default     = 365

  validation {
    condition     = var.log_retention_days >= 365
    error_message = "ISMS-P 기준 로그는 최소 1년(365일) 이상 보관해야 합니다."
  }
}

variable "report_retention_days" {
  description = "리포트 보존 기간 (ISMS-P: 최소 1년)"
  type        = number
  default     = 365
}

# =============================================================================
# Slack 알림 설정
# =============================================================================
variable "slack_webhook_url" {
  description = "Slack Webhook URL (kyeol-security-alerts 채널)"
  type        = string
  sensitive   = true
}

variable "slack_channel" {
  description = "Slack 채널명"
  type        = string
  default     = "#kyeol-security-alerts"
}

# =============================================================================
# Bedrock 설정 (AI 리포트 생성)
# =============================================================================
variable "bedrock_model_id" {
  description = "Bedrock 모델 ID (저비용: Claude Haiku 권장)"
  type        = string
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}

variable "bedrock_region" {
  description = "Bedrock 리전 (Sydney는 미지원, us-east-1 사용)"
  type        = string
  default     = "us-east-1"
}

# =============================================================================
# EventBridge 스케줄 설정
# =============================================================================
variable "enable_daily_report" {
  description = "일간 리포트 활성화"
  type        = bool
  default     = true
}

variable "enable_weekly_report" {
  description = "주간 리포트 활성화"
  type        = bool
  default     = true
}

variable "enable_monthly_report" {
  description = "월간 리포트 활성화"
  type        = bool
  default     = true
}

variable "daily_report_hour" {
  description = "일간 리포트 생성 시간 (UTC, 한국 09:00 = 0)"
  type        = number
  default     = 0
}

# =============================================================================
# ISMS-P 실시간 모니터링 이벤트 (보안 정책)
# =============================================================================
variable "security_events" {
  description = "실시간 모니터링할 CloudTrail 이벤트 목록 (ISMS-P 기준)"
  type        = list(string)
  default = [
    # 인증/권한 관련 (ISMS-P 2.5.1 접근권한 관리)
    "ConsoleLogin",
    "CreateUser",
    "DeleteUser",
    "CreateAccessKey",
    "DeleteAccessKey",
    "AttachUserPolicy",
    "DetachUserPolicy",
    "AttachRolePolicy",
    "CreateRole",
    "DeleteRole",
    # 네트워크 보안 (ISMS-P 2.6.1)
    "AuthorizeSecurityGroupIngress",
    "AuthorizeSecurityGroupEgress",
    "CreateSecurityGroup",
    "DeleteSecurityGroup",
    # 데이터 보호 (ISMS-P 2.7.1)
    "PutBucketPolicy",
    "DeleteBucketPolicy",
    "PutBucketPublicAccessBlock",
    # 암호화 (ISMS-P 2.7.2)
    "DisableKey",
    "ScheduleKeyDeletion",
    "CreateKey"
  ]
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

# WAF Module - Phase 3 신규 모듈 (Regional WAF for ALB)
# ap-southeast-2 (Sydney) 리전용

variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "environment" {
  description = "환경"
  type        = string
}

variable "alb_arn" {
  description = "WAF를 연결할 ALB ARN (Ingress가 생성한 ALB)"
  type        = string
  default     = ""
}

variable "enable_waf_association" {
  description = "WAF-ALB 연결 활성화 (ALB ARN 필요)"
  type        = bool
  default     = false
}

variable "waf_logs_bucket_arn" {
  description = "WAF 로그 저장용 S3 버킷 ARN"
  type        = string
  default     = ""
}

variable "enable_waf_logging" {
  description = "WAF 로깅 활성화"
  type        = bool
  default     = false
}

variable "rate_limit" {
  description = "Rate Limit (5분당 요청 수) - DEV:2000 / PROD:5000"
  type        = number
  default     = 2000
}

# P1: Count 모드 (운영 초기 필수)
variable "waf_rule_action_override" {
  description = "WAF 규칙 액션 오버라이드: 'none'(기본 Block) / 'count'(모니터링 모드)"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "count"], var.waf_rule_action_override)
    error_message = "waf_rule_action_override must be 'none' or 'count'"
  }
}

# P1: IP 화이트리스트 (관리자/헬스체크 예외)
variable "rate_limit_whitelist_ips" {
  description = "Rate Limit 예외 IP CIDR 목록 (관리자/헬스체크/모니터링)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

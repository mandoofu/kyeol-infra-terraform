# WAF Global Module - CloudFront용 (us-east-1)
# Global WAF는 CloudFront 앞단에 1개만 생성
# 모든 환경(DEV/STAGE/PROD)이 이 WAF를 공유

variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "rate_limit" {
  description = "Rate Limit (5분당 요청 수)"
  type        = number
  default     = 5000
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

variable "enable_logging" {
  description = "WAF 로깅 활성화"
  type        = bool
  default     = false
}

variable "waf_logs_bucket_arn" {
  description = "WAF 로그 S3 버킷 ARN (aws-waf-logs-* 접두사 필수)"
  type        = string
  default     = ""
}

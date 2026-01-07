# CloudFront Module - Phase 3 신규 모듈
# us-east-1 리전용 (CloudFront는 글로벌 서비스지만 ACM은 us-east-1 필수)

variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "environment" {
  description = "환경"
  type        = string
}

variable "domain" {
  description = "기본 도메인 (예: msp-g1.click)"
  type        = string
}

variable "domain_aliases" {
  description = "CloudFront에서 사용할 도메인 별칭 목록"
  type        = list(string)
  default     = []
}

variable "origin_domain" {
  description = "Origin 도메인 (예: origin-prod.msp-g1.click) - Route53에서 ALB로 ALIAS된 도메인"
  type        = string
}

variable "acm_certificate_arn" {
  description = "CloudFront용 ACM 인증서 ARN (us-east-1에서 발급)"
  type        = string
}

variable "waf_global_arn" {
  description = "CloudFront용 Global WAF Web ACL ARN (선택사항)"
  type        = string
  default     = ""
}

variable "logs_bucket_domain" {
  description = "로그 저장용 S3 버킷 도메인 (예: bucket-name.s3.amazonaws.com)"
  type        = string
  default     = ""
}

variable "enable_logging" {
  description = "CloudFront Access Log 활성화"
  type        = bool
  default     = false
}

variable "price_class" {
  description = "CloudFront Price Class (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_200" # 아시아/유럽/북미
}

variable "default_ttl" {
  description = "기본 캐시 TTL (초)"
  type        = number
  default     = 86400 # 1일
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

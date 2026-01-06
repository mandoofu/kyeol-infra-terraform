# Lambda@Edge Module - Phase 3 신규 모듈
# us-east-1 리전 필수 (모듈 호출 시 providers 전달)

variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "environment" {
  description = "환경"
  type        = string
}

variable "function_name_suffix" {
  description = "Lambda 함수 이름 접미사"
  type        = string
  default     = "edge"
}

variable "handler" {
  description = "Lambda 핸들러"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Lambda 런타임"
  type        = string
  default     = "nodejs18.x"
}

variable "timeout" {
  description = "Lambda 타임아웃 (초) - Viewer: 최대 5초, Origin: 최대 30초"
  type        = number
  default     = 5
}

variable "memory_size" {
  description = "Lambda 메모리 (MB)"
  type        = number
  default     = 128
}

variable "source_dir" {
  description = "Lambda 소스 코드 디렉터리 경로"
  type        = string
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

# Fluent Bit IRSA 변수 - Phase 3 추가
# 기본값 false로 기존 환경 영향 없음

variable "enable_fluent_bit_irsa" {
  description = "Fluent Bit IRSA 생성 여부"
  type        = bool
  default     = false
}

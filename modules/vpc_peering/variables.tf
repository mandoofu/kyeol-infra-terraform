# VPC Peering Module: 변수 정의
# MGMT VPC와 DEV/STAGE/PROD VPC 간 Peering 연결을 위한 변수

variable "name_prefix" {
  description = "리소스 이름 프리픽스 (예: min-kyeol-dev-mgmt)"
  type        = string
}

variable "environment" {
  description = "환경 이름 (dev, stage, prod)"
  type        = string
}

# Requester VPC (MGMT)
variable "requester_vpc_id" {
  description = "피어링 요청 VPC ID (MGMT)"
  type        = string
}

variable "requester_vpc_cidr" {
  description = "피어링 요청 VPC CIDR (MGMT)"
  type        = string
}

variable "requester_route_table_ids" {
  description = "피어링 요청 VPC 라우트 테이블 ID 목록 (MGMT)"
  type        = list(string)
}

# Accepter VPC (DEV/STAGE/PROD)
variable "accepter_vpc_id" {
  description = "피어링 수락 VPC ID (DEV/STAGE/PROD)"
  type        = string
}

variable "accepter_vpc_cidr" {
  description = "피어링 수락 VPC CIDR (DEV/STAGE/PROD)"
  type        = string
}

variable "accepter_route_table_ids" {
  description = "피어링 수락 VPC 라우트 테이블 ID 목록 (DEV/STAGE/PROD)"
  type        = list(string)
}

# DNS 해석 옵션
variable "allow_remote_vpc_dns_resolution" {
  description = "VPC Peering에서 원격 VPC DNS 해석 허용 여부"
  type        = bool
  default     = true
}

variable "tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}

# PROD Environment Variables

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_account_id" {
  description = "AWS 계정 ID"
  type        = string
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "kyeol"
}

variable "owner_prefix" {
  description = "소유자 프리픽스"
  type        = string
  default     = "min"
}

variable "environment" {
  description = "환경 이름"
  type        = string
  default     = "prod"
}

# VPC
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.30.0.0/16"
}

variable "azs" {
  description = "가용영역 목록"
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
}

# EKS
variable "eks_cluster_version" {
  description = "EKS 클러스터 버전"
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "EKS 노드 인스턴스 타입"
  type        = list(string)
  default     = ["t3.xlarge"]
}

variable "eks_node_desired_size" {
  description = "EKS 노드 희망 수"
  type        = number
  default     = 4
}

variable "eks_node_min_size" {
  description = "EKS 노드 최소 수"
  type        = number
  default     = 3
}

variable "eks_node_max_size" {
  description = "EKS 노드 최대 수"
  type        = number
  default     = 10
}

# RDS
variable "rds_instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.r6g.large"
}

variable "rds_multi_az" {
  description = "RDS Multi-AZ 활성화"
  type        = bool
  default     = true
}

variable "rds_allocated_storage" {
  description = "RDS 할당 스토리지 (GB)"
  type        = number
  default     = 100
}

variable "rds_deletion_protection" {
  description = "RDS 삭제 보호"
  type        = bool
  default     = true
}

variable "rds_backup_retention_period" {
  description = "RDS 백업 보존 기간 (일)"
  type        = number
  default     = 30
}

# Route53
variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID (msp-g1.click)"
  type        = string
}

# Cache (Valkey)
variable "enable_cache" {
  description = "Valkey 캐시 활성화"
  type        = bool
  default     = true
}

variable "cache_node_type" {
  description = "캐시 노드 타입"
  type        = string
  default     = "cache.r6g.large"
}

variable "cache_num_nodes" {
  description = "캐시 노드 수"
  type        = number
  default     = 3
}

# Monitoring
variable "enable_enhanced_monitoring" {
  description = "RDS Enhanced Monitoring 활성화"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logs" {
  description = "CloudWatch Logs 활성화"
  type        = bool
  default     = true
}

# =============================================================================
# Phase 3: 보안 & 모니터링 변수
# =============================================================================

# VPC Endpoints
variable "enable_s3_endpoint" {
  description = "S3 Gateway VPC Endpoint 활성화"
  type        = bool
  default     = false
}

variable "enable_ecr_endpoints" {
  description = "ECR API/DKR Interface VPC Endpoints 활성화"
  type        = bool
  default     = false
}

variable "enable_logs_endpoint" {
  description = "CloudWatch Logs Interface VPC Endpoint 활성화"
  type        = bool
  default     = false
}

variable "enable_sts_endpoint" {
  description = "STS Interface VPC Endpoint 활성화 (PROD 권장)"
  type        = bool
  default     = false
}

# 결제 전용 NAT Gateway
variable "enable_payment_nat" {
  description = "결제 전용 NAT Gateway 생성 (PG사 화이트리스트용 고정 EIP)"
  type        = bool
  default     = false
}

# 결제 전용 Node Group
variable "payment_node_instance_types" {
  description = "결제 노드 인스턴스 타입"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "payment_node_desired_size" {
  description = "결제 노드 희망 크기"
  type        = number
  default     = 1
}

variable "payment_node_min_size" {
  description = "결제 노드 최소 크기"
  type        = number
  default     = 1
}

variable "payment_node_max_size" {
  description = "결제 노드 최대 크기"
  type        = number
  default     = 2
}

# S3 버킷
variable "enable_phase3_s3" {
  description = "Phase 3 S3 버킷 (media, logs) 생성"
  type        = bool
  default     = false
}

variable "logs_retention_days" {
  description = "로그 보존 기간 (일)"
  type        = number
  default     = 90
}

# WAF
variable "enable_waf" {
  description = "WAF Web ACL 생성"
  type        = bool
  default     = false
}

variable "waf_alb_arn" {
  description = "WAF 연결용 ALB ARN (Ingress가 생성한 ALB)"
  type        = string
  default     = ""
}

variable "waf_rate_limit" {
  description = "WAF Rate Limit (5분당 요청 수)"
  type        = number
  default     = 5000 # PROD: 상향
}

# Fluent Bit IRSA
variable "enable_fluent_bit_irsa" {
  description = "Fluent Bit IRSA 생성"
  type        = bool
  default     = false
}

# CloudFront
variable "enable_cloudfront" {
  description = "CloudFront Distribution 생성"
  type        = bool
  default     = false
}

variable "cloudfront_acm_arn" {
  description = "CloudFront용 ACM 인증서 ARN (us-east-1)"
  type        = string
  default     = ""
}

variable "cloudfront_origin_alb_dns" {
  description = "Origin Route53 레코드용 ALB DNS Name"
  type        = string
  default     = ""
}

variable "cloudfront_origin_alb_zone_id" {
  description = "Origin Route53 레코드용 ALB Hosted Zone ID"
  type        = string
  default     = ""
}

variable "domain" {
  description = "기본 도메인 (예: msp-g1.click)"
  type        = string
  default     = "msp-g1.click"
}

# CloudTrail (P0: 계정당 1개 권장 - prod에서만 활성화)
variable "enable_cloudtrail" {
  description = "CloudTrail 활성화 - 계정당 1개만 권장 (prod에서만 true)"
  type        = bool
  default     = false
}

variable "enable_cloudtrail_data_events" {
  description = "CloudTrail S3/Lambda 데이터 이벤트 - PROD 권장"
  type        = bool
  default     = false
}

variable "enable_cloudtrail_cloudwatch" {
  description = "CloudTrail CloudWatch Logs 연동 - 실시간 알람 필요 시"
  type        = bool
  default     = false
}

variable "enable_cloudtrail_kms" {
  description = "CloudTrail KMS 암호화 - PROD 필수"
  type        = bool
  default     = false
}

variable "cloudtrail_kms_key_arn" {
  description = "CloudTrail KMS 키 ARN"
  type        = string
  default     = ""
}

# =============================================================================
# VPC Peering 설정 (MGMT ↔ PROD Private Endpoint 연결)
# =============================================================================
variable "enable_vpc_peering" {
  description = "MGMT VPC와 VPC Peering 활성화 (ArgoCD Private Endpoint 접근용)"
  type        = bool
  default     = false
}

variable "terraform_state_bucket" {
  description = "Terraform 상태 파일 S3 버킷 (MGMT State 참조용)"
  type        = string
  default     = ""
}

# EKS Endpoint 설정
variable "endpoint_private_access" {
  description = "EKS API Private Endpoint 활성화"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "EKS API Public Endpoint 활성화 (Private 전환 시 false)"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "EKS Public Endpoint 접근 허용 CIDR (최소화 권장)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "mgmt_vpc_cidrs" {
  description = "MGMT VPC CIDR (EKS Security Group에서 ArgoCD 접근 허용)"
  type        = list(string)
  default     = []
}


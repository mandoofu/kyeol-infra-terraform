# DEV Environment: S3 원격 백엔드
# Bootstrap에서 생성한 S3 버킷 사용

terraform {
  backend "s3" {
    bucket         = "min-kyeol-tfstate-827913617839-ap-southeast-2" # TODO: 실제 값으로 교체
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "min-kyeol-tfstate-lock"
    encrypt        = true
  }
}

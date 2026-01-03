# Terraform Remote State - STAGE Environment
terraform {
  backend "s3" {
    bucket         = "min-kyeol-tfstate-827913617839-ap-southeast-2"
    key            = "envs/stage/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "min-kyeol-tfstate-lock"
  }
}

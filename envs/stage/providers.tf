# AWS Provider Configuration - STAGE Environment
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Owner       = var.owner_prefix
      ManagedBy   = "terraform"
    }
  }
}

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

# Phase 3: us-east-1 Provider (CloudFront/Lambda@Edge용)
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Owner       = var.owner_prefix
      ManagedBy   = "terraform"
    }
  }
}

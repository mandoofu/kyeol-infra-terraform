# DEV Environment: AWS Provider 설정

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "kyeol"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "min"
    }
  }
}

# Phase 3: us-east-1 Provider (CloudFront/Lambda@Edge용)
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "kyeol"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "min"
    }
  }
}

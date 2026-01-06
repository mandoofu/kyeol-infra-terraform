# MGMT Environment: AWS Provider 설정

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "kyeol"
      Environment = "mgmt"
      ManagedBy   = "terraform"
      Owner       = "min"
    }
  }
}

# us-east-1 Provider (Global WAF, CloudFront ACM)
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "kyeol"
      Environment = "mgmt"
      ManagedBy   = "terraform"
      Owner       = "min"
    }
  }
}

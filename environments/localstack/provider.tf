# -----------------------------------------------------------------------------
# AWS Provider設定 (LocalStack用)
# -----------------------------------------------------------------------------

provider "aws" {
  region = "ap-northeast-1"

  endpoints {
    sqs            = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    iam            = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    logs           = "http://localhost:4566"
    s3             = "http://localhost:4566"
    sts            = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  access_key = "test"
  secret_key = "test"

  default_tags {
    tags = {
      Project     = "ProjectL"
      Environment = "localstack"
      ManagedBy   = "Terraform"
    }
  }
}

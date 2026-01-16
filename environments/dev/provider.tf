# -----------------------------------------------------------------------------
# AWS Provider設定
# -----------------------------------------------------------------------------

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "ProjectL"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

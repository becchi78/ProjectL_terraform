# -----------------------------------------------------------------------------
# Terraform Backend設定
# -----------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket  = "projectl-prod-terraform-tfstate"
    key     = "terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}

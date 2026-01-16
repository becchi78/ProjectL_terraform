# -----------------------------------------------------------------------------
# Terraform Backend設定
# -----------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket  = "projectl-dev-terraform-tfstate"
    key     = "terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}

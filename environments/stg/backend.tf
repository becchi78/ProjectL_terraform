# -----------------------------------------------------------------------------
# Terraform Backend設定
# -----------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket  = "projectl-stg-terraform-tfstate"
    key     = "terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}

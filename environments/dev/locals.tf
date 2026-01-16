# -----------------------------------------------------------------------------
# ローカル変数
# -----------------------------------------------------------------------------

locals {
  name_prefix = "projectl-${var.environment}"

  common_tags = {
    Project     = "ProjectL"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

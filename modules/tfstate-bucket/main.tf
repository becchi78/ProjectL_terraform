# -----------------------------------------------------------------------------
# tfstate用S3バケット
# -----------------------------------------------------------------------------

module "s3_bucket" {
  source = "../../../terraform-local/modules/s3_bucket"

  bucket = var.bucket_name

  # バージョニング有効化
  versioning = {
    enabled = true
  }

  # 暗号化設定
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # パブリックアクセスブロック
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = var.tags
}

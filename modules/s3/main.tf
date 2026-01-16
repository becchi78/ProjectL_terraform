# -----------------------------------------------------------------------------
# S3バケット
# -----------------------------------------------------------------------------

module "s3_bucket" {
  source = "../../../terraform-local/modules/s3_bucket"

  bucket = var.bucket_name

  # バージョニング設定
  versioning = {
    enabled = var.versioning_enabled
  }

  # 暗号化設定
  server_side_encryption_configuration = var.encryption_configuration

  # パブリックアクセスブロック (常にブロック)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # ライフサイクルルール (オプション)
  lifecycle_rule = var.lifecycle_rules

  tags = var.tags
}

# バケットポリシー (必須)
resource "aws_s3_bucket_policy" "this" {
  bucket = module.s3_bucket.s3_bucket_id
  policy = var.bucket_policy
}

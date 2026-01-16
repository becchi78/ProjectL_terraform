# -----------------------------------------------------------------------------
# 変数定義
# -----------------------------------------------------------------------------

variable "bucket_name" {
  description = "S3バケット名"
  type        = string
}

variable "versioning_enabled" {
  description = "バージョニングを有効化するかどうか"
  type        = bool
  default     = false
}

# 暗号化設定
variable "encryption_configuration" {
  description = <<-EOT
    サーバーサイド暗号化の設定。
    例 (AES256):
    {
      rule = {
        apply_server_side_encryption_by_default = {
          sse_algorithm = "AES256"
        }
      }
    }
    例 (KMS):
    {
      rule = {
        apply_server_side_encryption_by_default = {
          sse_algorithm     = "aws:kms"
          kms_master_key_id = "arn:aws:kms:ap-northeast-1:123456789012:key/xxx"
        }
      }
    }
  EOT
  type        = any
  default = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}

variable "bucket_policy" {
  description = "S3バケットポリシー (JSON文字列、必須)"
  type        = string
}

variable "lifecycle_rules" {
  description = "ライフサイクルルールのリスト"
  type        = any
  default     = []
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# 変数定義
# -----------------------------------------------------------------------------

variable "bucket_name" {
  description = "tfstate用S3バケット名"
  type        = string
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}

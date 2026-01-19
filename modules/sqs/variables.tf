# -----------------------------------------------------------------------------
# 変数定義
# -----------------------------------------------------------------------------

variable "queue_name" {
  description = "SQSキュー名"
  type        = string
}

# SQS設定
variable "message_retention_seconds" {
  description = "メッセージ保持期間 (秒)"
  type        = number
  default     = 345600 # 4 days
}

variable "visibility_timeout_seconds" {
  description = "可視性タイムアウト (秒)"
  type        = number
  default     = 30
}

# Dead Letter Queue設定
variable "create_dlq" {
  description = "Dead Letter Queueを作成するかどうか"
  type        = bool
  default     = true
}

variable "max_receive_count" {
  description = "DLQへ移動する前の最大受信回数"
  type        = number
  default     = 3
}

variable "dlq_message_retention_seconds" {
  description = "DLQのメッセージ保持期間 (秒)"
  type        = number
  default     = 1209600 # 14 days
}

# キューポリシー (オプション)
variable "queue_policy" {
  description = <<-EOT
    SQSキューポリシー (JSON文字列)。nullの場合はポリシーを作成しない。
    例:
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "AllowSendMessage"
          Effect    = "Allow"
          Principal = { AWS = "arn:aws:iam::123456789012:role/MyRole" }
          Action    = ["sqs:SendMessage"]
          Resource  = "*"
        }
      ]
    })
  EOT
  type        = string
  default     = null
}

# KMS暗号化設定
variable "kms_master_key_id" {
  description = "SQSキュー暗号化用のKMS Key ID。nullの場合はKMS暗号化を無効化"
  type        = string
  default     = null
}

variable "kms_data_key_reuse_period_seconds" {
  description = "KMSデータキーの再利用期間 (秒)"
  type        = number
  default     = 300
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}

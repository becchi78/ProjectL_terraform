# -----------------------------------------------------------------------------
# 変数定義 (LocalStack用簡略版)
# -----------------------------------------------------------------------------

variable "environment" {
  description = "環境名"
  type        = string
  default     = "localstack"
}

variable "region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

# Lambda関数定義
variable "lambda_functions" {
  description = "Lambda関数の定義マップ"
  type = map(object({
    runtime     = string
    handler     = string
    source_dir  = string
    memory_size = optional(number, 128)
    timeout     = optional(number, 30)
    description = optional(string, "")
  }))
}

# SQS設定
variable "sqs_message_retention_seconds" {
  description = "SQSメッセージ保持期間 (秒)"
  type        = number
  default     = 345600
}

variable "sqs_visibility_timeout_seconds" {
  description = "SQS可視性タイムアウト (秒)"
  type        = number
  default     = 30
}

variable "sqs_max_receive_count" {
  description = "DLQへ移動する前の最大受信回数"
  type        = number
  default     = 3
}

# SQS Event Source Mapping設定
variable "sqs_batch_size" {
  description = "SQSイベントのバッチサイズ"
  type        = number
  default     = 10
}

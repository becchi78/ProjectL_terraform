# -----------------------------------------------------------------------------
# 変数定義
# -----------------------------------------------------------------------------

# 基本情報
variable "environment" {
  description = "環境名"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prod", "localstack"], var.environment)
    error_message = "Environmentはdev, stg, prod, localstackのいずれかである必要があります。"
  }
}

variable "region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

# ネットワーク
variable "vpc_id" {
  description = "既存VPCのID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
}

variable "lambda_subnet_cidrs" {
  description = "Lambda用サブネットのCIDRリスト"
  type        = list(string)
}

variable "vpc_endpoint_subnet_cidrs" {
  description = "VPC Endpoint用サブネットのCIDRリスト"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "プライベートルートテーブルIDのリスト"
  type        = list(string)
}

# Aurora
variable "aurora_sg_id" {
  description = "Aurora Security GroupのID"
  type        = string
}

variable "aurora_port" {
  description = "Auroraのポート番号"
  type        = number
  default     = 5432
}

# ROSA
variable "worker_node_sg_id" {
  description = "Worker Node Security GroupのID"
  type        = string
}

variable "rosa_pod_iam_role_arn" {
  description = "ROSA Pod用IAM RoleのARN"
  type        = string
}

# Lambda関数定義
variable "lambda_functions" {
  description = "Lambda関数の定義マップ"
  type = map(object({
    runtime      = string
    handler      = string
    source_dir   = string
    memory_size  = optional(number, 128)
    timeout      = optional(number, 30)
    description  = optional(string, "")
    secrets_name = string # Lambda関数ごとのSecrets Manager Secret名
  }))
}

# SQS設定
variable "sqs_message_retention_seconds" {
  description = "SQSメッセージ保持期間 (秒)"
  type        = number
  default     = 345600 # 4 days
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

# KMS (SQS暗号化用)
variable "kms_key_deletion_window_in_days" {
  description = "KMSキー削除待機期間 (日)"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window_in_days >= 7 && var.kms_key_deletion_window_in_days <= 30
    error_message = "KMSキー削除待機期間は7日から30日の間である必要があります。"
  }
}

variable "kms_key_enable_rotation" {
  description = "KMSキーの自動ローテーションを有効にするかどうか"
  type        = bool
  default     = true
}

variable "kms_key_description" {
  description = "KMSキーの説明"
  type        = string
  default     = "KMS key for SQS encryption"
}

# SQS Event Source Mapping設定
variable "sqs_batch_size" {
  description = "SQSイベントのバッチサイズ"
  type        = number
  default     = 10
}

variable "sqs_maximum_concurrency" {
  description = "SQSイベントソースの最大同時実行数"
  type        = number
  default     = 10
}

# CloudWatch
variable "cloudwatch_logs_retention_days" {
  description = "CloudWatch Logsの保持期間 (日)"
  type        = number
  default     = 30
}

# S3 (Lambda出力用)
variable "s3_lambda_output_versioning_enabled" {
  description = "Lambda出力用S3バケットのバージョニングを有効化"
  type        = bool
  default     = false
}

variable "s3_lambda_output_lifecycle_rules" {
  description = "Lambda出力用S3バケットのライフサイクルルール"
  type        = any
  default     = []
}

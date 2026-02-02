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

# Processor1 - Lambda設定
variable "processor1_runtime" {
  description = "Processor1のランタイム"
  type        = string
  default     = "nodejs20.x"
}

variable "processor1_handler" {
  description = "Processor1のハンドラ"
  type        = string
  default     = "index.handler"
}

variable "processor1_source_dir" {
  description = "Processor1のソースディレクトリ"
  type        = string
  default     = "lambda-functions/processor1"
}

variable "processor1_memory_size" {
  description = "Processor1のメモリサイズ (MB)"
  type        = number
  default     = 128
}

variable "processor1_timeout" {
  description = "Processor1のタイムアウト (秒)"
  type        = number
  default     = 30
}

variable "processor1_description" {
  description = "Processor1の説明"
  type        = string
  default     = "SQS processor 1 (Node.js)"
}

variable "processor1_secrets_name" {
  description = "Processor1のSecrets Manager Secret名"
  type        = string
}

# Processor1 - SQS設定
variable "processor1_sqs_message_retention_seconds" {
  description = "Processor1 SQSメッセージ保持期間 (秒)"
  type        = number
  default     = 345600 # 4 days
}

variable "processor1_sqs_visibility_timeout_seconds" {
  description = "Processor1 SQS可視性タイムアウト (秒)"
  type        = number
  default     = 30
}

variable "processor1_sqs_max_receive_count" {
  description = "Processor1 DLQへ移動する前の最大受信回数"
  type        = number
  default     = 3
}

variable "processor1_sqs_batch_size" {
  description = "Processor1 SQSイベントのバッチサイズ"
  type        = number
  default     = 10
}

variable "processor1_sqs_maximum_concurrency" {
  description = "Processor1 SQSイベントソースの最大同時実行数"
  type        = number
  default     = 10
}

variable "processor1_cloudwatch_logs_retention_days" {
  description = "Processor1 CloudWatch Logsの保持期間 (日)"
  type        = number
  default     = 30
}

# Processor2 - Lambda設定
variable "processor2_runtime" {
  description = "Processor2のランタイム"
  type        = string
  default     = "python3.9"
}

variable "processor2_handler" {
  description = "Processor2のハンドラ"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "processor2_source_dir" {
  description = "Processor2のソースディレクトリ"
  type        = string
  default     = "lambda-functions/processor2"
}

variable "processor2_memory_size" {
  description = "Processor2のメモリサイズ (MB)"
  type        = number
  default     = 256
}

variable "processor2_timeout" {
  description = "Processor2のタイムアウト (秒)"
  type        = number
  default     = 60
}

variable "processor2_description" {
  description = "Processor2の説明"
  type        = string
  default     = "SQS processor 2 (Python)"
}

variable "processor2_secrets_name" {
  description = "Processor2のSecrets Manager Secret名"
  type        = string
}

# Processor2 - SQS設定
variable "processor2_sqs_message_retention_seconds" {
  description = "Processor2 SQSメッセージ保持期間 (秒)"
  type        = number
  default     = 345600 # 4 days
}

variable "processor2_sqs_visibility_timeout_seconds" {
  description = "Processor2 SQS可視性タイムアウト (秒)"
  type        = number
  default     = 360
}

variable "processor2_sqs_max_receive_count" {
  description = "Processor2 DLQへ移動する前の最大受信回数"
  type        = number
  default     = 3
}

variable "processor2_sqs_batch_size" {
  description = "Processor2 SQSイベントのバッチサイズ"
  type        = number
  default     = 10
}

variable "processor2_sqs_maximum_concurrency" {
  description = "Processor2 SQSイベントソースの最大同時実行数"
  type        = number
  default     = 10
}

variable "processor2_cloudwatch_logs_retention_days" {
  description = "Processor2 CloudWatch Logsの保持期間 (日)"
  type        = number
  default     = 30
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

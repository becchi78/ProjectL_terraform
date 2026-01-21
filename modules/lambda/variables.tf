# -----------------------------------------------------------------------------
# 変数定義
# -----------------------------------------------------------------------------

variable "function_name" {
  description = "Lambda関数名"
  type        = string
}

variable "description" {
  description = "Lambda関数の説明"
  type        = string
  default     = ""
}

# Lambda基本設定
variable "runtime" {
  description = "Lambda Runtime (例: nodejs20.x, python3.12)"
  type        = string
}

variable "handler" {
  description = "Lambda Handler (例: index.handler, lambda_function.lambda_handler)"
  type        = string
}

variable "memory_size" {
  description = "メモリサイズ (MB)"
  type        = number
  default     = 128
}

variable "timeout" {
  description = "タイムアウト (秒)"
  type        = number
  default     = 30
}

variable "source_path" {
  description = "Lambda関数のソースコードパス"
  type        = string
}

# VPC設定 (オプション)
variable "vpc_subnet_ids" {
  description = "Lambda用サブネットIDのリスト (VPC内で実行する場合に指定)"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "Lambda用Security GroupのIDリスト (VPC内で実行する場合に指定)"
  type        = list(string)
  default     = []
}

# IAM
variable "lambda_role_arn" {
  description = "Lambda実行ロールのARN"
  type        = string
}

# 環境変数
variable "environment_variables" {
  description = <<-EOT
    Lambda関数の環境変数。
    例:
    {
      DB_HOST     = "localhost"
      DB_PORT     = "5432"
      LOG_LEVEL   = "INFO"
    }
  EOT
  type        = map(string)
  default     = {}
}

# Lambda Layers
variable "layers" {
  description = <<-EOT
    Lambda LayerのARNリスト。
    例: ["arn:aws:lambda:ap-northeast-1:133490724326:layer:AWS-Parameters-and-Secrets-Lambda-Extension:12"]
  EOT
  type        = list(string)
  default     = []
}

# SQS Event Source Mapping (オプション)
variable "sqs_event_source" {
  description = <<-EOT
    SQSイベントソースの設定。nullの場合はEvent Source Mappingを作成しない。
    例:
    {
      queue_arn            = "arn:aws:sqs:ap-northeast-1:123456789012:my-queue"
      batch_size           = 10
      batching_window_seconds = 0
      maximum_concurrency  = 10
      enabled              = true
    }
  EOT
  type = object({
    queue_arn               = string
    batch_size              = optional(number, 10)
    batching_window_seconds = optional(number, 0)
    maximum_concurrency     = optional(number)
    enabled                 = optional(bool, true)
  })
  default = null
}

# CloudWatch
variable "cloudwatch_logs_retention_days" {
  description = "CloudWatch Logsの保持期間 (日)"
  type        = number
  default     = 30
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}

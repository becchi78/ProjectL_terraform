# -----------------------------------------------------------------------------
# 変数定義
# -----------------------------------------------------------------------------

variable "name" {
  description = "VPC Endpointの名前 (Nameタグに使用)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "service_name" {
  description = <<-EOT
    AWSサービス名。
    例:
    - "com.amazonaws.ap-northeast-1.sqs"
    - "com.amazonaws.ap-northeast-1.secretsmanager"
    - "com.amazonaws.ap-northeast-1.s3"
  EOT
  type        = string
}

variable "vpc_endpoint_type" {
  description = "VPC Endpointのタイプ (Interface または Gateway)"
  type        = string
  default     = "Interface"

  validation {
    condition     = contains(["Interface", "Gateway"], var.vpc_endpoint_type)
    error_message = "vpc_endpoint_typeはInterface または Gatewayである必要があります。"
  }
}

# Interface Endpoint用設定
variable "subnet_ids" {
  description = "Interface Endpoint用サブネットIDのリスト"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Interface Endpoint用Security GroupのIDリスト"
  type        = list(string)
  default     = []
}

variable "private_dns_enabled" {
  description = "プライベートDNSを有効化するかどうか (Interface Endpointのみ)"
  type        = bool
  default     = true
}

# Gateway Endpoint用設定
variable "route_table_ids" {
  description = "Gateway Endpoint用ルートテーブルIDのリスト"
  type        = list(string)
  default     = []
}

# VPC Endpointポリシー (オプション)
variable "policy" {
  description = <<-EOT
    VPC Endpointポリシー (JSON文字列)。nullの場合はデフォルトポリシーが適用される。
    例:
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "AllowAll"
          Effect    = "Allow"
          Principal = "*"
          Action    = "*"
          Resource  = "*"
        }
      ]
    })
  EOT
  type        = string
  default     = null
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}

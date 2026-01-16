# -----------------------------------------------------------------------------
# 変数定義
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "name_prefix" {
  description = "リソース名のプレフィックス (例: projectl-dev)"
  type        = string
}

variable "az_count" {
  description = "使用するアベイラビリティゾーンの数"
  type        = number
  default     = 2
}

variable "subnets" {
  description = <<-EOT
    作成するサブネットのマップ。キーがサブネット名のサフィックスになる。
    例:
    {
      "lambda-0" = {
        cidr_block = "10.0.100.0/24"
        az_index   = 0
        tags       = { Type = "Lambda" }
      }
      "lambda-1" = {
        cidr_block = "10.0.101.0/24"
        az_index   = 1
        tags       = { Type = "Lambda" }
      }
    }
  EOT
  type = map(object({
    cidr_block = string
    az_index   = number
    tags       = optional(map(string), {})
  }))
  default = {}
}

variable "route_table_id" {
  description = "関連付けるルートテーブルID (空の場合は関連付けを行わない)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# 変数定義
# -----------------------------------------------------------------------------

variable "name" {
  description = "Security Groupの名前"
  type        = string
}

variable "description" {
  description = "Security Groupの説明"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

# Ingressルール
variable "ingress_with_source_security_group_id" {
  description = <<-EOT
    ソースSecurity Groupを指定するIngressルールのリスト。
    例:
    [
      {
        description              = "From web servers"
        from_port                = 443
        to_port                  = 443
        protocol                 = "tcp"
        source_security_group_id = "sg-xxx"
      }
    ]
  EOT
  type        = list(any)
  default     = []
}

variable "ingress_with_cidr_blocks" {
  description = <<-EOT
    CIDRブロックを指定するIngressルールのリスト。
    例:
    [
      {
        description = "From VPC"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = "10.0.0.0/16"
      }
    ]
  EOT
  type        = list(any)
  default     = []
}

variable "ingress_with_self" {
  description = "自己参照Ingressルールのリスト"
  type        = list(any)
  default     = []
}

# Egressルール
variable "egress_with_source_security_group_id" {
  description = "ソースSecurity Groupを指定するEgressルールのリスト"
  type        = list(any)
  default     = []
}

variable "egress_with_cidr_blocks" {
  description = "CIDRブロックを指定するEgressルールのリスト"
  type        = list(any)
  default     = []
}

# 追加のルール (循環参照回避用)
variable "additional_ingress_rules" {
  description = <<-EOT
    追加のIngressルールのマップ (循環参照回避やモジュール作成後の追加用)。
    例:
    {
      "from-lambda" = {
        from_port                = 443
        to_port                  = 443
        protocol                 = "tcp"
        source_security_group_id = "sg-xxx"
        description              = "From Lambda"
      }
    }
  EOT
  type        = map(any)
  default     = {}
}

variable "additional_egress_rules" {
  description = "追加のEgressルールのマップ"
  type        = map(any)
  default     = {}
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}

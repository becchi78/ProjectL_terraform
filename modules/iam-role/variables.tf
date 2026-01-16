# -----------------------------------------------------------------------------
# 変数定義
# -----------------------------------------------------------------------------

variable "role_name" {
  description = "IAMロール名"
  type        = string
}

variable "trusted_role_services" {
  description = <<-EOT
    信頼するAWSサービスのリスト。
    例: ["lambda.amazonaws.com", "ec2.amazonaws.com"]
  EOT
  type        = list(string)
  default     = []
}

variable "trusted_role_arns" {
  description = <<-EOT
    信頼するIAMロール/ユーザーのARNリスト。
    例: ["arn:aws:iam::123456789012:role/OtherRole"]
  EOT
  type        = list(string)
  default     = []
}

variable "role_policy_arns" {
  description = <<-EOT
    アタッチするマネージドポリシーのARNリスト。
    例: ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
  EOT
  type        = list(string)
  default     = []
}

variable "inline_policy_statements" {
  description = <<-EOT
    インラインポリシーのステートメントリスト。
    例:
    [
      {
        sid       = "S3Access"
        actions   = ["s3:GetObject", "s3:PutObject"]
        resources = ["arn:aws:s3:::my-bucket/*"]
      }
    ]
  EOT
  type = list(object({
    sid       = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}

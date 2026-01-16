# -----------------------------------------------------------------------------
# 汎用IAM Roleモジュール
# -----------------------------------------------------------------------------

module "this" {
  source = "../../../terraform-local/modules/iam_role"

  role_name = var.role_name

  # 信頼ポリシー
  trusted_role_services = var.trusted_role_services
  trusted_role_arns     = var.trusted_role_arns

  # マネージドポリシー
  role_policy_arns = var.role_policy_arns

  # インラインポリシー
  inline_policy_statements = var.inline_policy_statements

  tags = var.tags
}

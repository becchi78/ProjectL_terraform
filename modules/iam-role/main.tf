# -----------------------------------------------------------------------------
# 汎用IAM Roleモジュール
# -----------------------------------------------------------------------------

locals {
  # trusted_role_servicesとtrusted_role_arnsからtrust_policy_permissionsを構築
  service_principals = length(var.trusted_role_services) > 0 ? {
    for idx, service in var.trusted_role_services :
    "service_${idx}" => {
      sid     = "ServicePrincipal${idx}"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = [service]
      }]
    }
  } : {}

  role_principals = length(var.trusted_role_arns) > 0 ? {
    for idx, arn in var.trusted_role_arns :
    "role_${idx}" => {
      sid     = "RolePrincipal${idx}"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "AWS"
        identifiers = [arn]
      }]
    }
  } : {}

  trust_policy_permissions = merge(local.service_principals, local.role_principals)

  # role_policy_arnsをpoliciesマップに変換
  policies = {
    for idx, arn in var.role_policy_arns :
    "policy_${idx}" => arn
  }

  # inline_policy_statementsをinline_policy_permissionsマップに変換
  inline_policy_permissions = {
    for stmt in var.inline_policy_statements :
    stmt.sid => {
      sid       = stmt.sid
      actions   = stmt.actions
      resources = stmt.resources
    }
  }
}

module "this" {
  source = "../../terraform-local/modules/iam_role/modules/iam-role"

  name = var.role_name

  # 信頼ポリシー
  trust_policy_permissions = length(local.trust_policy_permissions) > 0 ? local.trust_policy_permissions : null

  # マネージドポリシー
  policies = local.policies

  # インラインポリシー
  create_inline_policy      = length(var.inline_policy_statements) > 0
  inline_policy_permissions = length(local.inline_policy_permissions) > 0 ? local.inline_policy_permissions : null

  tags = var.tags
}

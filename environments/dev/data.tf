# -----------------------------------------------------------------------------
# 既存リソースの参照
# -----------------------------------------------------------------------------

# 現在のAWSアカウント情報
data "aws_caller_identity" "current" {}

# Secrets Manager Secret (Lambda関数ごと)
data "aws_secretsmanager_secret" "lambda" {
  for_each = var.lambda_functions

  name = each.value.secrets_name
}

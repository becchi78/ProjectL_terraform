# -----------------------------------------------------------------------------
# 既存リソースの参照
# -----------------------------------------------------------------------------

# 現在のAWSアカウント情報
data "aws_caller_identity" "current" {}

# Secrets Manager Secret
data "aws_secretsmanager_secret" "processor1" {
  name = var.processor1_secrets_name
}

data "aws_secretsmanager_secret" "processor2" {
  name = var.processor2_secrets_name
}

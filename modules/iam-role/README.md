# iam-role モジュール

IAM Role を作成します。

## 機能

- IAM Role 作成
- 信頼ポリシー (AssumeRole) 設定
- マネージドポリシーのアタッチ
- インラインポリシーの作成

## 使用方法

### Lambda 実行ロールの例

```hcl
module "lambda_execution_role" {
  source = "../../modules/iam-role"

  role_name = "projectl-dev-lambda-execution-role"

  # 信頼ポリシー: Lambda サービスからの AssumeRole を許可
  trusted_role_services = ["lambda.amazonaws.com"]

  # マネージドポリシーをアタッチ
  role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]

  # インラインポリシー
  inline_policy_statements = [
    {
      sid = "S3Access"
      actions = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      resources = [
        "arn:aws:s3:::my-bucket/*"
      ]
    },
    {
      sid = "SecretsManagerAccess"
      actions = [
        "secretsmanager:GetSecretValue"
      ]
      resources = [
        "arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:my-secret-*"
      ]
    }
  ]

  tags = {
    Project     = "ProjectL"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### クロスアカウントアクセス用ロールの例

```hcl
module "cross_account_role" {
  source = "../../modules/iam-role"

  role_name = "projectl-dev-cross-account-role"

  # 他のアカウントのロールからの AssumeRole を許可
  trusted_role_arns = [
    "arn:aws:iam::987654321098:role/ExternalRole"
  ]

  # マネージドポリシー
  role_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]

  tags = {
    Project     = "ProjectL"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### EC2 インスタンスロールの例

```hcl
module "ec2_instance_role" {
  source = "../../modules/iam-role"

  role_name = "projectl-dev-ec2-instance-role"

  # EC2 サービスからの AssumeRole を許可
  trusted_role_services = ["ec2.amazonaws.com"]

  # マネージドポリシー
  role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  # インラインポリシー
  inline_policy_statements = [
    {
      sid = "CloudWatchMetrics"
      actions = [
        "cloudwatch:PutMetricData"
      ]
      resources = ["*"]
    }
  ]

  tags = {
    Project     = "ProjectL"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## 入力変数

| 名前 | 説明 | 型 | 必須 | デフォルト |
|------|------|------|------|------------|
| role_name | IAMロール名 | string | Yes | - |
| trusted_role_services | 信頼するAWSサービスのリスト (例: ["lambda.amazonaws.com"]) | list(string) | No | [] |
| trusted_role_arns | 信頼するIAMロール/ユーザーのARNリスト | list(string) | No | [] |
| role_policy_arns | アタッチするマネージドポリシーのARNリスト | list(string) | No | [] |
| inline_policy_statements | インラインポリシーのステートメントリスト | list(object) | No | [] |
| tags | リソースに付与するタグ | map(string) | No | {} |

### inline_policy_statements オブジェクトの構造

```hcl
{
  sid       = string           # Statement ID
  actions   = list(string)     # IAMアクション (例: ["s3:GetObject"])
  resources = list(string)     # リソースARN (例: ["arn:aws:s3:::bucket/*"])
}
```

## 出力値

| 名前 | 説明 |
|------|------|
| role_arn | IAMロールのARN |
| role_name | IAMロールの名前 |
| role_id | IAMロールのID (Unique ID) |

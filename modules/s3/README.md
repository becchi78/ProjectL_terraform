# s3 モジュール

汎用的なS3バケットを作成します。

## 機能

- S3バケット作成
- AES256暗号化
- パブリックアクセスブロック
- バージョニング (オプション)
- ライフサイクルルール (オプション)
- カスタムバケットポリシー (オプション)

## 使用方法

### 基本的な使用例

```hcl
module "s3_data" {
  source = "../../modules/s3"

  bucket_name        = "projectl-dev-data"
  versioning_enabled = false

  tags = {
    Project     = "ProjectL"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### ライフサイクルルール付き

```hcl
module "s3_logs" {
  source = "../../modules/s3"

  bucket_name        = "projectl-dev-logs"
  versioning_enabled = false

  lifecycle_rules = [
    {
      id      = "expire-old-logs"
      enabled = true
      expiration = {
        days = 90
      }
    }
  ]

  tags = {
    Project     = "ProjectL"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### カスタムバケットポリシー付き

```hcl
module "s3_shared" {
  source = "../../modules/s3"

  bucket_name        = "projectl-dev-shared"
  versioning_enabled = true

  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:role/lambda-role"
        }
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::projectl-dev-shared/*"
      }
    ]
  })

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
| bucket_name | S3バケット名 | string | Yes | - |
| versioning_enabled | バージョニング有効化 | bool | No | false |
| bucket_policy | S3バケットポリシー (JSON文字列) | string | No | null |
| lifecycle_rules | ライフサイクルルール | any | No | [] |
| tags | リソースに付与するタグ | map(string) | No | {} |

## 出力値

| 名前 | 説明 |
|------|------|
| bucket_id | S3バケットのID |
| bucket_arn | S3バケットのARN |
| bucket_name | S3バケット名 |
| bucket_region | S3バケットのリージョン |
| bucket_domain_name | S3バケットのドメイン名 |

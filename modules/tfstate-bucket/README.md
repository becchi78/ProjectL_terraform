# tfstate-bucket モジュール

Terraform state ファイル用の S3 バケットを作成します。

## 機能

- バージョニング有効化
- AES256 暗号化
- パブリックアクセスブロック

## 使用方法

```hcl
module "tfstate_bucket" {
  source = "../../modules/tfstate-bucket"

  bucket_name = "projectl-dev-terraform-tfstate"

  tags = {
    Project     = "ProjectL"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## 入力変数

| 名前 | 説明 | 型 | 必須 |
|------|------|------|------|
| bucket_name | S3バケット名 | string | Yes |
| tags | リソースに付与するタグ | map(string) | No |

## 出力値

| 名前 | 説明 |
|------|------|
| bucket_id | S3バケットのID |
| bucket_arn | S3バケットのARN |
| bucket_region | S3バケットのリージョン |

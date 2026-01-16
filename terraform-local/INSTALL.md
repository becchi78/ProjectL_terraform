# オフライン環境インストール手順

踏み台サーバ (dev/stg/prod) はインターネットアクセスが制限されているため、
事前にダウンロードしたリソースを使用して Terraform を実行します。

## ディレクトリ構成

```
terraform-local/
├── binary/                  # Terraformバイナリ
│   └── terraform_1.14.3_linux_amd64.zip
├── providers/               # AWSプロバイダ
│   └── registry.terraform.io/
│       └── hashicorp/
│           └── aws/
│               └── 6.27.0/
│                   └── linux_amd64/
│                       └── terraform-provider-aws_v6.27.0
└── modules/                 # 公式モジュール
    ├── cloudwatch/          # v5.7.2
    ├── iam_role/            # v6.3.0
    ├── kms/                 # v4.2.0
    ├── lambda_function/     # v8.2.0
    ├── s3_bucket/           # v5.10.0
    ├── security_group/      # v5.3.1
    ├── sqs/                 # v5.2.0
    └── vpc/                 # v6.6.0
```

## セットアップ手順

### 1. Terraform バイナリのインストール

```bash
cd terraform-local/binary
unzip terraform_1.14.3_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform version
```

### 2. Terraform 初期化 (オフラインモード)

各環境ディレクトリで以下のコマンドを実行:

```bash
cd environments/dev
terraform init -plugin-dir=../../terraform-local/providers
```

## モジュール参照

プロジェクト内のモジュールは `terraform-local/modules/` から相対パスで参照します:

```hcl
# 正しい参照方法
module "sqs" {
  source = "../../terraform-local/modules/sqs"
  # ...
}

# 間違った参照方法 (レジストリからダウンロードしようとするためエラー)
module "sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.0"
  # ...
}
```

## プロバイダ設定

各環境の `versions.tf` で以下のように設定:

```hcl
terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27.0"
    }
  }
}
```

## トラブルシューティング

### プロバイダが見つからないエラー

```
Error: Failed to query available provider packages
```

**解決方法**: `-plugin-dir` オプションを確認

```bash
terraform init -plugin-dir=../../terraform-local/providers
```

### モジュールが見つからないエラー

```
Error: Module not found
```

**解決方法**: モジュールの相対パスを確認

```bash
ls ../../terraform-local/modules/
```

### バージョン不一致エラー

**解決方法**: `terraform-local/modules/` 内のモジュールバージョンを確認

```bash
cat ../../terraform-local/modules/modules.json
```

## 新しいモジュールの追加方法

インターネット接続可能な環境で以下を実行:

```bash
# 1. 一時ディレクトリで初期化
mkdir temp && cd temp
cat > main.tf << 'EOF'
module "new_module" {
  source  = "terraform-aws-modules/xxx/aws"
  version = "x.x.x"
}
EOF

# 2. モジュールをダウンロード
terraform init

# 3. ダウンロードしたモジュールをコピー
cp -r .terraform/modules/new_module ../../terraform-local/modules/

# 4. 一時ディレクトリを削除
cd .. && rm -rf temp
```

## バージョン情報

| コンポーネント | バージョン |
|----------------|------------|
| Terraform | 1.14.3 |
| AWS Provider | 6.27.0 |
| SQS Module | 5.2.0 |
| Lambda Module | 8.2.0 |
| Security Group Module | 5.3.1 |
| IAM Role Module | 6.3.0 |
| CloudWatch Module | 5.7.2 |
| S3 Bucket Module | 5.10.0 |
| VPC Module | 6.6.0 |
| KMS Module | 4.2.0 |

# ProjectL Terraform プロジェクト要件定義書

## プロジェクト概要

このプロジェクトは、Terraform を使用して以下のリソースをデプロイします:

- **SQS**: メッセージキュー (+ Dead Letter Queue)
- **Lambda**: VPC Lambda 関数 (Aurora 接続)
- **VPC Endpoint**: SQS 用 VPC エンドポイント
- **Networking**: Lambda 用サブネット、SQS Endpoint 用サブネット
- **Security**: Security Groups、IAM Roles

## 基本情報

- **プロジェクト名**: ProjectL
- **環境**: dev/stg/prod/localstack
- **リージョン**: ap-northeast-1（東京）
- **デプロイ方法**:
  - dev/stg/prod: AWS 上に構築した Linux の踏み台サーバで実行
  - localstack: 開発者のローカル PC で実行
- **AWS アカウント**: dev/stg/prod はそれぞれ別の AWS アカウント
- **システム構成**: Pod(ROSA) → SQS → Lambda → Aurora

## アーキテクチャ構成

```
VPC (既存)
├── Worker Node Subnet (既存) ────────┐
├── Lambda Subnet (Terraform作成) ────┼→ SQS VPC Endpoint
└── SQS Endpoint Subnet (Terraform作成)└→ (ここにエンドポイント配置)
                                          ↓
                                         SQS
                                          ↓
                                        Lambda
                                          ↓
                                        Aurora
```

**アクセスフロー:**

1. ROSA Pod (Worker Node Subnet) → SQS VPC Endpoint → SQS
2. SQS → Lambda (Lambda Subnet 内)
3. Lambda → Aurora (既存)

## バージョン管理

- **Terraform**: 1.14.3
- **AWS Provider**: 6.27.0
- **モジュール**:
  - SQS: 5.1.0 (terraform-aws-modules/sqs/aws)
  - Lambda: 8.1.2 (terraform-aws-modules/lambda/aws)

## State 管理

- **Backend**: S3
- **バケット名**: `ProjectL-{env}-terraform-tfstate`
- **バージョニング**: 有効
- **暗号化**: 有効 (AES256 or KMS)
- **DynamoDB ロック**: 不要 (各環境 1 台の踏み台サーバのみ)

## オフライン環境対応

dev/stg/prod の踏み台サーバは外部との通信が制限されているため:

1. **Terraform バイナリ**: `terraform-local/` ディレクトリに配置
2. **公式モジュール**: `terraform-local/modules/` ディレクトリに事前ダウンロード
3. **初期化方法**: インターネットアクセスなしで `terraform init` できる構成

## ディレクトリ構造

```
ProjectL-terraform/
├── README.md                        # プロジェクト概要
├── .gitmodules                      # Lambda関数のSubmodule設定
│
├── terraform-local/                 # オフライン環境用
│   ├── INSTALL.md                   # ローカルインストール手順
│   ├── binary                       # v1.14.3バイナリ
│   ├── providers                    # AWSプロバイダ
│   └── modules/
│       ├── cloudwatch/
│       └── iam_role/
│
├── lambda-functions/               # Git Submodule (別リポジトリ)
│   ├── processor1/
│   │   └── index.js or lambda_function.py
│   └── processor2/
│       └── lambda_function.py
│
├── environments/
│   ├── dev/
│   │   ├── main.tf                 # 環境固有のリソース定義
│   │   ├── variables.tf            # 環境固有の変数
│   │   ├── terraform.tfvars        # 変数値
│   │   ├── backend.tf              # S3 backend設定
│   │   └── outputs.tf              # 出力値
│   ├── stg/
│   ├── prod/
│   └── localstack/
│
└── modules/
    ├── tfstate-bucket/             # tfstate用S3バケット作成
    ├── networking/                 # Lambda/SQS Endpoint用サブネット
    ├── sqs/                        # SQS + DLQ + VPCエンドポイント
    ├── lambda/                     # Lambda関数
    └── security/                   # SG, IAMロール
```

## リソース仕様

### 1. Networking

#### Lambda 用サブネット

- **命名規則**: `ProjectL-{env}-lambda-subnet-{az}`
- **CIDR**: variables.tf で指定可能
- **作成数**: 2 (Multi-AZ)
- **Route Table**: 既存のプライベートルートテーブルに関連付け

#### SQS Endpoint 用サブネット

- **命名規則**: `ProjectL-{env}-sqs-endpoint-subnet-{az}`
- **CIDR**: variables.tf で指定可能
- **作成数**: 2 (Multi-AZ)
- **用途**: SQS VPC エンドポイント配置

### 2. SQS

#### メインキュー

- **命名規則**: `ProjectL-{env}-sqs-{function-name}`
- **設定**:
  - メッセージ保持期間: デフォルト値、variables.tf で変更可能
  - 可視性タイムアウト: デフォルト値、variables.tf で変更可能
  - Dead Letter Queue: 有効
  - CloudWatch Logs: 有効
  - CloudWatch Metrics: 有効

#### Dead Letter Queue

- **命名規則**: `ProjectL-{env}-sqs-{function-name}-dlq`
- **maxReceiveCount**: variables.tf で設定可能 (デフォルト: 3)

#### VPC エンドポイント

- **タイプ**: Interface Endpoint
- **サービス**: com.amazonaws.ap-northeast-1.sqs
- **サブネット**: SQS Endpoint Subnet
- **セキュリティグループ**:
  - Inbound: Worker Node SG、Lambda SG から 443 許可
- **ポリシー**: ROSA Pod の IAM Role からのアクセスを許可

#### アクセス制御

- **送信元**: ROSA Pod にアタッチされている IAM Role
- **IAM Role ARN**: `arn:aws:iam::123456789012:role/ProjectL-rosa-pod-role` (仮置き)

### 3. Lambda

#### 基本設定

- **命名規則**: `ProjectL-{env}-lambda-{function-name}`
- **Runtime**: Node.js または Python (関数ごとに指定)
- **メモリ**: デフォルト 128MB、variables.tf で変更可能
- **タイムアウト**: variables.tf で設定可能
- **VPC 設定**:
  - サブネット: Lambda Subnet (Multi-AZ)
  - セキュリティグループ: Lambda 用 SG
- **Layer**: 今のところ使用しない

#### デプロイ方法

- **ソースコード**: Git Submodule (`lambda-functions/`)
- **リポジトリ URL**: `https://github.com/your-org/ProjectL-lambda-functions.git` (仮置き)
- **ビルドプロセス**: 不要
- **デプロイ**: `terraform apply` 時に自動デプロイ
  - Submodule のコードを参照して zip アーカイブ作成

#### 環境変数

```hcl
environment {
  variables = {
    AURORA_SECRET_NAME = var.aurora_secret_name  # 環境ごとに異なる
    # その他の環境変数はvariables.tfで追加可能
  }
}
```

#### Secrets Manager 連携

- **Extension**: AWS Parameters and Secrets Lambda Extension
- **Secret 名**:
  - dev: `lnkr-dev-aurora` (仮置き)
  - stg: `lnkr-stg-aurora` (仮置き)
  - prod: `lnkr-prod-aurora` (仮置き)
- **参照方法**: 環境変数 `AURORA_SECRET_NAME` から取得
- **IAM 権限**: Lambda 実行ロールに `secretsmanager:GetSecretValue` 付与

#### SQS トリガー

- **イベントソースマッピング**: 有効
- **バッチサイズ**: variables.tf で設定可能
- **同時実行数**: variables.tf で設定可能

### 4. Security Groups

#### Lambda 用 SG

- **命名規則**: `ProjectL-{env}-lambda-sg`
- **Egress**:
  - Aurora SG: 3306/5432 (DB ポート)
  - SQS Endpoint SG: 443
  - VPC エンドポイント (Secrets Manager): 443

#### SQS VPC エンドポイント用 SG

- **命名規則**: `ProjectL-{env}-sqs-endpoint-sg`
- **Ingress**:
  - Worker Node SG: 443
  - Lambda SG: 443

#### Aurora 用 SG (既存 SG に追加)

- **SG 名**: `ProjectL-{env}-aurora-lambda-access-sg` (仮置き)
- **Ingress**:
  - Lambda SG: 3306 or 5432

### 5. IAM Roles

#### Lambda 実行ロール

- **命名規則**: `ProjectL-{env}-lambda-execution-role`
- **ポリシー**:
  - AWSLambdaVPCAccessExecutionRole (Managed Policy)
  - Secrets Manager 読み取り (インラインポリシー)
  - SQS 読み取り・削除 (インラインポリシー)
  - CloudWatch Logs 書き込み (インラインポリシー)

## データソース (既存リソース参照)

以下のリソースは既存のため、data source で参照すること:

```hcl
# VPC
data "aws_vpc" "main" {
  id = var.vpc_id  # vpc-xxxxxxxxx (仮置き)
}

# Worker Node用サブネット
data "aws_subnets" "worker_node" {
  filter {
    name   = "subnet-id"
    values = var.worker_node_subnet_ids  # ["subnet-xxxxxxxx", "subnet-yyyyyyyy"] (仮置き)
  }
}

# Aurora Cluster
data "aws_rds_cluster" "aurora" {
  cluster_identifier = var.aurora_cluster_id  # "ProjectL-aurora-cluster" (仮置き)
}

# Aurora SG
data "aws_security_group" "aurora" {
  id = var.aurora_sg_id  # "sg-xxxxxxxxx" (仮置き)
}

# Worker Node SG
data "aws_security_group" "worker_node" {
  id = var.worker_node_sg_id  # "sg-xxxxxxxxx" (仮置き)
}
```

## 命名規則

すべてのリソースは以下の命名規則に従うこと:

| リソース              | パターン                                |
| --------------------- | --------------------------------------- |
| S3 Bucket (tfstate)   | `ProjectL-{env}-terraform-tfstate`        |
| Subnet (Lambda)       | `ProjectL-{env}-lambda-subnet-{az}`       |
| Subnet (SQS Endpoint) | `ProjectL-{env}-sqs-endpoint-subnet-{az}` |
| SQS Queue             | `ProjectL-{env}-sqs-{function-name}`      |
| DLQ                   | `ProjectL-{env}-sqs-{function-name}-dlq`  |
| Lambda Function       | `ProjectL-{env}-lambda-{function-name}`   |
| Security Group        | `ProjectL-{env}-{resource}-sg`            |
| IAM Role              | `ProjectL-{env}-{resource}-role`          |
| VPC Endpoint          | `ProjectL-{env}-sqs-endpoint`             |

## タグ戦略

すべてのリソースに以下の共通タグを付与すること:

```hcl
tags = {
  Project     = "ProjectL"
  Environment = var.environment  # dev/stg/prod
  ManagedBy   = "Terraform"
}
```

## 環境別変数

各環境の `terraform.tfvars` で以下を設定可能にすること:

```hcl
# 基本情報
environment = "dev"
region      = "ap-northeast-1"

# ネットワーク
vpc_id                    = "vpc-xxxxxxxxx"
worker_node_subnet_ids    = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
lambda_subnet_cidrs       = ["10.0.10.0/24", "10.0.11.0/24"]
sqs_endpoint_subnet_cidrs = ["10.0.20.0/24", "10.0.21.0/24"]

# Aurora
aurora_cluster_id  = "ProjectL-aurora-cluster"
aurora_sg_id       = "sg-xxxxxxxxx"
aurora_secret_name = "lnkr-dev-aurora"

# ROSA
worker_node_sg_id     = "sg-xxxxxxxxx"
rosa_pod_iam_role_arn = "arn:aws:iam::123456789012:role/ProjectL-rosa-pod-role"

# Lambda関数定義
lambda_functions = {
  processor1 = {
    runtime     = "nodejs20.x"
    handler     = "index.handler"
    source_dir  = "lambda-functions/processor1"
    memory_size = 128
    timeout     = 30
  }
  processor2 = {
    runtime     = "python3.12"
    handler     = "lambda_function.lambda_handler"
    source_dir  = "lambda-functions/processor2"
    memory_size = 256
    timeout     = 60
  }
}

# SQS設定
sqs_message_retention_seconds  = 345600  # 4 days
sqs_visibility_timeout_seconds = 30
sqs_max_receive_count          = 3
```

## Localstack 対応

`environments/localstack/` では以下の設定を行うこと:

### backend.tf

```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

### provider.tf

```hcl
provider "aws" {
  region = "ap-northeast-1"

  endpoints {
    sqs            = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    iam            = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  access_key = "test"
  secret_key = "test"
}
```

## コード生成時の注意事項

### 1. モジュールの参照

- 公式モジュールは `terraform-local/modules/` から相対パスで参照
- 例: `source = "../../../terraform-local/modules/terraform-aws-sqs-5.1.0"`

### 2. オフライン環境での初期化

- `terraform init` が外部通信なしで成功するように設定
- `-plugin-dir` オプションまたは `.terraformrc` で対応

### 3. 複数 Lambda 関数への対応

- `for_each` を使用して Lambda 関数を動的に生成
- 各関数に対して SQS + DLQ のペアを作成

### 4. エラーハンドリング

- Data source が見つからない場合のエラーメッセージを明確に
- 変数の validation を適切に設定

### 5. ドキュメント

- 各モジュールに `README.md` を作成
- `terraform-local/INSTALL.md` にオフラインインストール手順を記載
- トップレベルの `README.md` から参照

## 期待される出力

コード生成時には以下を含めること:

1. **完全なディレクトリ構造**
2. **各環境の Terraform コード** (dev/stg/prod/localstack)
3. **再利用可能なモジュール**
4. **変数定義と説明**
5. **README.md** (使用方法、前提条件)
6. **INSTALL.md** (オフライン環境セットアップ手順)

## 参考情報

- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/6.27.0
- AWS SQS Module: https://registry.terraform.io/modules/terraform-aws-modules/sqs/aws/5.1.0
- AWS Lambda Module: https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws/8.1.2
- AWS Parameters and Secrets Lambda Extension: https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieving-secrets_lambda.html

# ProjectL Terraform

Terraform を使用して AWS インフラストラクチャをデプロイするプロジェクトです。

## 構成

```
ProjectL_Terraform/
├── environments/           # 環境別設定
│   ├── dev/               # 開発環境
│   ├── stg/               # ステージング環境
│   ├── prod/              # 本番環境
│   └── localstack/        # ローカルテスト環境
│
├── modules/               # 再利用可能なモジュール
│   ├── tfstate-bucket/    # tfstate用S3バケット
│   ├── s3/                # S3バケット (汎用)
│   ├── networking/        # サブネット設定
│   ├── sqs/               # SQS + DLQ + VPCエンドポイント
│   ├── lambda/            # Lambda関数
│   └── security/          # Security Groups, IAM Roles
│
├── terraform-local/       # オフライン環境用
│   ├── binary/            # Terraformバイナリ
│   ├── providers/         # AWSプロバイダ
│   └── modules/           # 公式モジュール
│
└── lambda-functions/      # Lambda関数ソースコード (Git Submodule)
    ├── processor1/
    └── processor2/
```

## デプロイリソース

- **SQS**: メッセージキュー + Dead Letter Queue
- **Lambda**: VPC Lambda関数 (Aurora接続)
- **S3**: Lambda出力用バケット
- **VPC Endpoint**: SQS用VPCエンドポイント
- **Networking**: Lambda用サブネット、SQS Endpoint用サブネット
- **Security**: Security Groups、IAM Roles

## 前提条件

- Terraform 1.14.3
- AWS Provider 6.27.0
- 既存リソース:
  - VPC
  - Worker Nodeサブネット
  - Aurora Cluster
  - Worker Node Security Group
  - Aurora Security Group

## バージョン情報

### Terraform & Provider

| コンポーネント | バージョン |
|----------------|------------|
| Terraform | 1.14.3 |
| AWS Provider | 6.27.0 |

### 公式モジュール (terraform-local/modules/)

| モジュール | バージョン | 用途 |
|------------|------------|------|
| terraform-aws-modules/sqs/aws | 5.2.0 | SQSキュー作成 |
| terraform-aws-modules/lambda/aws | 8.2.0 | Lambda関数作成 |
| terraform-aws-modules/security-group/aws | 5.3.1 | Security Group作成 |
| terraform-aws-modules/iam/aws (iam-role) | 6.3.0 | IAMロール作成 |
| terraform-aws-modules/cloudwatch/aws (log-group) | 5.7.2 | CloudWatch Log Group作成 |
| terraform-aws-modules/s3-bucket/aws | 5.10.0 | S3バケット作成 |
| terraform-aws-modules/vpc/aws | 6.6.0 | VPC関連 (参照用) |
| terraform-aws-modules/kms/aws | 4.2.0 | KMS (参照用) |

## 各環境のファイル構成

各環境 (`environments/dev`, `stg`, `prod`, `localstack`) は以下のファイルで構成されています:

| ファイル | 説明 |
|----------|------|
| `versions.tf` | Terraform および Provider のバージョン指定 |
| `backend.tf` | State 管理設定 (S3 または local) |
| `provider.tf` | AWS Provider 設定 |
| `variables.tf` | 入力変数の定義 |
| `locals.tf` | ローカル変数の定義 |
| `data.tf` | 既存リソースの参照 (data source) |
| `main.tf` | リソース定義 (モジュール呼び出し) |
| `outputs.tf` | 出力値の定義 |
| `terraform.tfvars.example` | 変数値のサンプル |

**注意**: `localstack` 環境は VPC 機能が限定的なため、`data.tf` がなく簡略化された構成になっています。

## 使用方法

### ローカル環境 (LocalStack)

```bash
cd environments/localstack
terraform init
terraform plan
terraform apply
```

### 踏み台サーバ (dev/stg/prod)

踏み台サーバはオフライン環境のため、`terraform-local/` のリソースを使用します。
詳細は [terraform-local/INSTALL.md](terraform-local/INSTALL.md) を参照してください。

```bash
cd environments/dev
terraform init -plugin-dir=../../terraform-local/providers
terraform plan -out=plan.tfplan
terraform apply plan.tfplan
```

## 環境変数

各環境の `terraform.tfvars` で以下を設定:

| 変数名 | 説明 |
|--------|------|
| `environment` | 環境名 (dev/stg/prod/localstack) |
| `vpc_id` | 既存VPCのID |
| `worker_node_subnet_ids` | Worker Nodeサブネットのリスト |
| `lambda_subnet_cidrs` | Lambda用サブネットのCIDRリスト |
| `sqs_endpoint_subnet_cidrs` | SQS Endpoint用サブネットのCIDRリスト |
| `aurora_cluster_id` | Aurora ClusterのID |
| `aurora_sg_id` | Aurora Security GroupのID |
| `aurora_secret_name` | Secrets ManagerのSecret名 |
| `worker_node_sg_id` | Worker Node Security GroupのID |
| `rosa_pod_iam_role_arn` | ROSA Pod用IAM RoleのARN |
| `lambda_functions` | Lambda関数の定義マップ |
| `s3_lambda_output_versioning_enabled` | Lambda出力用S3バケットのバージョニング有効化 |
| `s3_lambda_output_lifecycle_rules` | Lambda出力用S3バケットのライフサイクルルール |

## 命名規則

| リソース | パターン |
|----------|----------|
| S3 Bucket (tfstate) | `projectl-{env}-terraform-tfstate` |
| S3 Bucket (Lambda出力) | `projectl-{env}-lambda-output` |
| Subnet (Lambda) | `projectl-{env}-lambda-subnet-{az}` |
| Subnet (SQS Endpoint) | `projectl-{env}-sqs-endpoint-subnet-{az}` |
| SQS Queue | `projectl-{env}-sqs-{function-name}` |
| DLQ | `projectl-{env}-sqs-{function-name}-dlq` |
| Lambda Function | `projectl-{env}-lambda-{function-name}` |
| Security Group | `projectl-{env}-{resource}-sg` |
| IAM Role | `projectl-{env}-{resource}-role` |
| VPC Endpoint | `projectl-{env}-sqs-endpoint` |

## タグ戦略

すべてのリソースに以下のタグを付与:

```hcl
tags = {
  Project     = "ProjectL"
  Environment = var.environment
  ManagedBy   = "Terraform"
}
```

## 注意事項

- コミット前に `terraform fmt -recursive` を実行
- `terraform.tfvars` はコミットしない (機密情報を含む可能性あり)
- 本番適用前に必ず `terraform plan` の出力をレビュー

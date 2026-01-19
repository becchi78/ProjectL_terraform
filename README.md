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
│   ├── s3/                # S3バケット
│   ├── networking/        # サブネット設定
│   ├── sqs/               # SQS + DLQ
│   ├── vpc-endpoint/      # VPC Endpoint
│   ├── lambda/            # Lambda関数
│   ├── security-group/    # Security Groups
│   └── iam-role/          # IAM Roles
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
- **VPC Endpoint**: SQS用VPCエンドポイント
- **Lambda**: VPC Lambda関数 (Aurora接続)
- **S3**: Lambda出力用バケット
- **KMS**: SQS暗号化用KMSキー
- **Networking**: Lambda用サブネット、VPC Endpoint用サブネット
- **Security Groups**: Lambda用、SQS Endpoint用
- **IAM Roles**: Lambda実行ロール

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

## Apply後の手動作業

Terraform apply 実行後、既存リソースに対して以下の手動変更が必要です。

### 1. Aurora Security Groupへのルール追加（必須）

LambdaからAuroraへの接続を許可するため、Aurora Security Groupにingressルールを追加してください。

**Lambda Security Group IDの取得:**

```bash
terraform output lambda_sg_id
```

出力例: `sg-0a1b2c3d4e5f6g7h8`

**AWSコンソールでの作業:**

1. EC2 > Security Groups > Aurora Security Group を開く
2. Inbound rules > Edit inbound rules をクリック
3. Add rule で以下を追加:
   - **Type**: PostgreSQL (または Custom TCP)
   - **Protocol**: TCP
   - **Port**: `5432` (または設定したポート番号)
   - **Source**: Custom - 上記で取得したLambda Security Group ID (`sg-xxxxxxxxx`)
   - **Description**: `Lambda access to Aurora`
4. Save rules をクリック

### 2. Worker Node Security Groupの確認（必要に応じて）

Worker NodeからSQS VPC Endpointへの通信を確認してください。

**SQS Endpoint Security Group IDの取得:**

```bash
terraform output sqs_endpoint_sg_id
```

出力例: `sg-9h8g7f6e5d4c3b2a1`

**確認手順:**

1. EC2 > Security Groups > Worker Node Security Group を開く
2. Outbound rules タブを確認
3. 以下のいずれかが設定されていることを確認:
   - VPC内への全通信許可 (`10.0.0.0/16` など)
   - 全ての送信先への通信許可 (`0.0.0.0/0`)
   - SQS VPC Endpoint SGへの443ポート通信許可

**通常はegressルールが広く設定されているため変更不要ですが、制限的な設定の場合は以下を追加:**

1. Outbound rules > Edit outbound rules をクリック
2. Add rule で以下を追加:
   - **Type**: HTTPS
   - **Protocol**: TCP
   - **Port**: 443
   - **Destination**: Custom - 上記で取得したSQS Endpoint Security Group ID (`sg-xxxxxxxxx`)
   - **Description**: `SQS VPC Endpoint access`
3. Save rules をクリック

### 3. 動作確認

手動変更完了後、以下を確認してください:

- [ ] Lambda関数がAuroraに接続できることを確認
- [ ] Worker NodeのPodがSQSにメッセージを送信できることを確認
- [ ] LambdaがSQSからメッセージを受信できることを確認

## 環境変数

各環境の `terraform.tfvars` で以下を設定:

| 変数名 | 説明 |
|--------|------|
| `environment` | 環境名 (dev/stg/prod/localstack) |
| `region` | AWSリージョン |
| `vpc_id` | 既存VPCのID |
| `vpc_cidr` | VPCのCIDRブロック |
| `lambda_subnet_cidrs` | Lambda用サブネットのCIDRリスト |
| `vpc_endpoint_subnet_cidrs` | VPC Endpoint用サブネットのCIDRリスト |
| `private_route_table_ids` | プライベートルートテーブルIDのリスト |
| `aurora_sg_id` | Aurora Security GroupのID |
| `aurora_port` | Auroraのポート番号 |
| `worker_node_sg_id` | Worker Node Security GroupのID |
| `rosa_pod_iam_role_arn` | ROSA Pod用IAM RoleのARN |
| `lambda_functions` | Lambda関数の定義マップ（secrets_nameを含む） |
| `sqs_message_retention_seconds` | SQSメッセージ保持期間 (秒) |
| `sqs_visibility_timeout_seconds` | SQS可視性タイムアウト (秒) |
| `sqs_max_receive_count` | DLQへ移動する前の最大受信回数 |
| `kms_key_deletion_window_in_days` | KMSキー削除待機期間 (日、7-30の範囲) |
| `kms_key_enable_rotation` | KMSキーの自動ローテーションを有効にするかどうか |
| `kms_key_description` | KMSキーの説明 |
| `sqs_batch_size` | SQSイベントのバッチサイズ |
| `sqs_maximum_concurrency` | SQSイベントソースの最大同時実行数 |
| `cloudwatch_logs_retention_days` | CloudWatch Logsの保持期間 (日) |
| `s3_lambda_output_versioning_enabled` | Lambda出力用S3バケットのバージョニング有効化 |
| `s3_lambda_output_lifecycle_rules` | Lambda出力用S3バケットのライフサイクルルール |

## 命名規則

| リソース | パターン |
|----------|----------|
| S3 Bucket (tfstate) | `projectl-{env}-terraform-tfstate` |
| S3 Bucket (Lambda出力) | `projectl-{env}-lambda-output` |
| Subnet (Lambda) | `projectl-{env}-subnet-lambda-{idx}` |
| Subnet (VPC Endpoint) | `projectl-{env}-subnet-vpc-endpoint-{idx}` |
| SQS Queue | `projectl-{env}-sqs-{function-name}` |
| DLQ | `projectl-{env}-sqs-{function-name}-dlq` |
| Lambda Function | `projectl-{env}-lambda-{function-name}` |
| Security Group (Lambda) | `projectl-{env}-lambda-sg` |
| Security Group (SQS Endpoint) | `projectl-{env}-sqs-endpoint-sg` |
| IAM Role (Lambda) | `projectl-{env}-lambda-execution-role` |
| VPC Endpoint (SQS) | `projectl-{env}-sqs-endpoint` |
| KMS Key (SQS) | `projectl-{env}-sqs-kms-key` |
| KMS Alias (SQS) | `alias/projectl-{env}-sqs` |

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
- **重要**: `terraform apply` 実行後、必ず「Apply後の手動作業」セクションの手順を実施すること
  - Aurora SGへのLambda SGからのアクセス許可が必須
  - Worker Node SGのegress設定確認が必要な場合あり

# ProjectL Terraform

Terraform を使用して AWS インフラストラクチャをデプロイするプロジェクトです。

## 構成

```text
ProjectL_Terraform/
├── environments/           # 環境別設定
│   ├── dev/               # 開発環境
│   ├── stg/               # ステージング環境
│   ├── prod/              # 本番環境
│   └── localstack/        # ローカルテスト環境
│
├── modules/               # 再利用可能なモジュール
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
- **VPC Endpoint**: SQS 用 VPC エンドポイント
- **Lambda**: VPC Lambda 関数 (Aurora 接続)
- **S3**: Lambda 出力用バケット
- **KMS**: SQS 暗号化用 KMS キー
- **Networking**: Lambda 用サブネット、VPC Endpoint 用サブネット
- **Security Groups**: Lambda 用、SQS Endpoint 用
- **IAM Roles**: Lambda 実行ロール

## 前提条件

- Terraform 1.14.3
- AWS Provider 6.27.0
- 既存リソース:
  - VPC
  - プライベートルートテーブル
  - Aurora Security Group
  - Worker Node Security Group
  - ROSA Pod IAM Role

## バージョン情報

### Terraform & Provider

| コンポーネント | バージョン  |
| -------------- | ----------- |
| Terraform      | >= 1.14.0   |
| AWS Provider   | ~> 6.28.0   |

### 公式モジュール (terraform-local/modules/)

| モジュール                                       | バージョン | 用途                      |
| ------------------------------------------------ | ---------- | ------------------------- |
| terraform-aws-modules/sqs/aws                    | 5.2.0      | SQS キュー作成            |
| terraform-aws-modules/lambda/aws                 | 8.2.0      | Lambda 関数作成           |
| terraform-aws-modules/security-group/aws         | 5.3.1      | Security Group 作成       |
| terraform-aws-modules/iam/aws (iam-role)         | 6.3.0      | IAM ロール作成            |
| terraform-aws-modules/cloudwatch/aws (log-group) | 5.7.2      | CloudWatch Log Group 作成 |
| terraform-aws-modules/s3-bucket/aws              | 5.10.0     | S3 バケット作成           |
| terraform-aws-modules/vpc/aws                    | 6.6.0      | VPC 関連                  |
| terraform-aws-modules/kms/aws                    | 4.2.0      | KMS                       |

## 各環境のファイル構成

各環境 (`environments/dev`, `stg`, `prod`, `localstack`) は以下のファイルで構成されています:

| ファイル / ディレクトリ    | 説明                                       |
| -------------------------- | ------------------------------------------ |
| `versions.tf`              | Terraform および Provider のバージョン指定 |
| `backend.tf`               | State 管理設定 (S3 または local)           |
| `provider.tf`              | AWS Provider 設定                          |
| `variables.tf`             | 入力変数の定義                             |
| `locals.tf`                | ローカル変数の定義                         |
| `data.tf`                  | 既存リソースの参照 (data source)           |
| `main.tf`                  | リソース定義 (モジュール呼び出し)          |
| `outputs.tf`               | 出力値の定義                               |
| `terraform.tfvars.example` | 変数値のサンプル                           |
| `policies/`                | IAM/SQS/VPC Endpoint ポリシー JSON ファイル |

**注意**: `localstack` 環境は VPC 機能が限定的なため、`data.tf` がなく簡略化された構成になっています。

## 初期セットアップ

### tfstate 保存用 S3 バケットの作成

踏み台サーバで Terraform を使用開始する前に、tfstate を保存する S3 バケットを作成する必要があります。
最初期段階では Terraform がまだ使えないため、AWS CLI で手動作成してください。

各環境で以下のコマンドを実行してください。

**dev 環境の例:**

```bash
# 環境変数を設定
ENV="dev"
BUCKET_NAME="projectl-${ENV}-terraform-tfstate"
REGION="ap-northeast-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
```

```bash
# 1. KMSキーを作成
KMS_KEY_ID=$(aws kms create-key \
  --description "ProjectL ${ENV} Terraform tfstate S3 bucket encryption key" \
  --policy file://policies/tfstate-bucket-kms-key-policy.json \
  --query 'KeyMetadata.KeyId' \
  --output text)

echo "Created KMS Key: ${KMS_KEY_ID}"

# 2. S3バケットを作成
aws s3api create-bucket \
  --bucket ${BUCKET_NAME} \
  --region ${REGION} \
  --create-bucket-configuration LocationConstraint=${REGION}

echo "Created S3 bucket: ${BUCKET_NAME}"

# 3. バージョニングを有効化
aws s3api put-bucket-versioning \
  --bucket ${BUCKET_NAME} \
  --versioning-configuration Status=Enabled

# 4. KMSキーで暗号化を有効化
aws s3api put-bucket-encryption \
  --bucket ${BUCKET_NAME} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms",
        "KMSMasterKeyID": "'${KMS_KEY_ID}'"
      },
      "BucketKeyEnabled": true
    }]
  }'

# 5. パブリックアクセスブロックを設定
aws s3api put-public-access-block \
  --bucket ${BUCKET_NAME} \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# 6. タグを設定
aws s3api put-bucket-tagging \
  --bucket ${BUCKET_NAME} \
  --tagging 'TagSet=[
    {Key=Project,Value=ProjectL},
    {Key=Environment,Value='${ENV}'},
    {Key=ManagedBy,Value=Manual}
  ]'
```

**stg/prod 環境の場合:**

上記コマンドの `ENV="dev"` を `ENV="stg"` または `ENV="prod"` に置き換えて実行してください。

#### 作成確認

バケットとKMSキーが正しく作成されたことを確認:

```bash
# 環境に合わせて設定
ENV="dev"
BUCKET_NAME="projectl-${ENV}-terraform-tfstate"

# 暗号化設定からKMSキーIDを取得
KMS_KEY_ID=$(aws s3api get-bucket-encryption \
  --bucket ${BUCKET_NAME} \
  --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.KMSMasterKeyID' \
  --output text)

echo "KMS Key ID: ${KMS_KEY_ID}"

# KMSキーの確認
echo "=== KMS Key ==="
aws kms describe-key --key-id ${KMS_KEY_ID}

# S3バケットのバージョニング確認
echo "=== Bucket Versioning ==="
aws s3api get-bucket-versioning --bucket ${BUCKET_NAME}

# S3バケットの暗号化確認
echo "=== Bucket Encryption ==="
aws s3api get-bucket-encryption --bucket ${BUCKET_NAME}

# パブリックアクセスブロック確認
echo "=== Public Access Block ==="
aws s3api get-public-access-block --bucket ${BUCKET_NAME}

# タグの確認
echo "=== Bucket Tags ==="
aws s3api get-bucket-tagging --bucket ${BUCKET_NAME}
```

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

## Apply 後の手動作業

Terraform apply 実行後、既存リソースに対して以下の手動変更が必要です。

### 1. Aurora Security Group へのルール追加（必須）

Lambda から Aurora への接続を許可するため、Aurora Security Group に ingress ルールを追加してください。

**Lambda Security Group ID の取得:**

```bash
terraform output lambda_sg_id
```

出力例: `sg-0a1b2c3d4e5f6g7h8`

**AWS コンソールでの作業:**

1. EC2 > Security Groups > Aurora Security Group を開く
2. Inbound rules > Edit inbound rules をクリック
3. Add rule で以下を追加:
   - **Type**: PostgreSQL (または Custom TCP)
   - **Protocol**: TCP
   - **Port**: `5432` (または設定したポート番号)
   - **Source**: Custom - 上記で取得した Lambda Security Group ID (`sg-xxxxxxxxx`)
   - **Description**: `Lambda access to Aurora`
4. Save rules をクリック

### 2. Worker Node Security Group の確認（必要に応じて）

Worker Node から SQS VPC Endpoint への通信を確認してください。

**SQS Endpoint Security Group ID の取得:**

```bash
terraform output sqs_endpoint_sg_id
```

出力例: `sg-9h8g7f6e5d4c3b2a1`

**確認手順:**

1. EC2 > Security Groups > Worker Node Security Group を開く
2. Outbound rules タブを確認
3. 以下のいずれかが設定されていることを確認:
   - VPC 内への全通信許可 (`10.0.0.0/16` など)
   - 全ての送信先への通信許可 (`0.0.0.0/0`)
   - SQS VPC Endpoint SG への 443 ポート通信許可

**通常は egress ルールが広く設定されているため変更不要ですが、制限的な設定の場合は以下を追加:**

1. Outbound rules > Edit outbound rules をクリック
2. Add rule で以下を追加:
   - **Type**: HTTPS
   - **Protocol**: TCP
   - **Port**: 443
   - **Destination**: Custom - 上記で取得した SQS Endpoint Security Group ID (`sg-xxxxxxxxx`)
   - **Description**: `SQS VPC Endpoint access`
3. Save rules をクリック

### 3. 動作確認

手動変更完了後、以下を確認してください:

- [ ] Lambda 関数が Aurora に接続できることを確認
- [ ] Worker Node の Pod が SQS にメッセージを送信できることを確認
- [ ] Lambda が SQS からメッセージを受信できることを確認

## 環境変数

各環境の `terraform.tfvars` で以下を設定:

### 基本情報

| 変数名                  | 説明                         |
| ----------------------- | ---------------------------- |
| `environment`           | 環境名 (dev/stg/prod/localstack) |
| `region`                | AWS リージョン               |

### ネットワーク

| 変数名                      | 説明                                   |
| --------------------------- | -------------------------------------- |
| `vpc_id`                    | 既存 VPC の ID                         |
| `vpc_cidr`                  | VPC の CIDR ブロック                   |
| `lambda_subnet_cidrs`       | Lambda 用サブネットの CIDR リスト      |
| `vpc_endpoint_subnet_cidrs` | VPC Endpoint 用サブネットの CIDR リスト |
| `private_route_table_ids`   | プライベートルートテーブル ID のリスト |

### Aurora

| 変数名         | 説明                        |
| -------------- | --------------------------- |
| `aurora_sg_id` | Aurora Security Group の ID |
| `aurora_port`  | Aurora のポート番号         |

### ROSA

| 変数名                  | 説明                        |
| ----------------------- | --------------------------- |
| `worker_node_sg_id`     | Worker Node Security Group の ID |
| `rosa_pod_iam_role_arn` | ROSA Pod 用 IAM Role の ARN |

### Processor1 - Lambda 設定

| 変数名                      | 説明                          |
| --------------------------- | ----------------------------- |
| `processor1_runtime`        | Processor1 のランタイム       |
| `processor1_handler`        | Processor1 のハンドラ         |
| `processor1_source_dir`     | Processor1 のソースディレクトリ |
| `processor1_memory_size`    | Processor1 のメモリサイズ (MB) |
| `processor1_timeout`        | Processor1 のタイムアウト (秒) |
| `processor1_description`    | Processor1 の説明             |
| `processor1_secrets_name`   | Processor1 の Secrets Manager Secret 名 |

### Processor1 - SQS 設定

| 変数名                                         | 説明                                    |
| ---------------------------------------------- | --------------------------------------- |
| `processor1_sqs_message_retention_seconds`     | Processor1 SQS メッセージ保持期間 (秒)  |
| `processor1_sqs_visibility_timeout_seconds`    | Processor1 SQS 可視性タイムアウト (秒)  |
| `processor1_sqs_max_receive_count`             | Processor1 DLQ へ移動する前の最大受信回数 |
| `processor1_sqs_batch_size`                    | Processor1 SQS イベントのバッチサイズ   |
| `processor1_sqs_maximum_concurrency`           | Processor1 SQS イベントソースの最大同時実行数 |
| `processor1_cloudwatch_logs_retention_days`    | Processor1 CloudWatch Logs の保持期間 (日) |

### Processor2 - Lambda 設定

| 変数名                      | 説明                          |
| --------------------------- | ----------------------------- |
| `processor2_runtime`        | Processor2 のランタイム       |
| `processor2_handler`        | Processor2 のハンドラ         |
| `processor2_source_dir`     | Processor2 のソースディレクトリ |
| `processor2_memory_size`    | Processor2 のメモリサイズ (MB) |
| `processor2_timeout`        | Processor2 のタイムアウト (秒) |
| `processor2_description`    | Processor2 の説明             |
| `processor2_secrets_name`   | Processor2 の Secrets Manager Secret 名 |

### Processor2 - SQS 設定

| 変数名                                         | 説明                                    |
| ---------------------------------------------- | --------------------------------------- |
| `processor2_sqs_message_retention_seconds`     | Processor2 SQS メッセージ保持期間 (秒)  |
| `processor2_sqs_visibility_timeout_seconds`    | Processor2 SQS 可視性タイムアウト (秒)  |
| `processor2_sqs_max_receive_count`             | Processor2 DLQ へ移動する前の最大受信回数 |
| `processor2_sqs_batch_size`                    | Processor2 SQS イベントのバッチサイズ   |
| `processor2_sqs_maximum_concurrency`           | Processor2 SQS イベントソースの最大同時実行数 |
| `processor2_cloudwatch_logs_retention_days`    | Processor2 CloudWatch Logs の保持期間 (日) |

### KMS (SQS 暗号化用)

| 変数名                            | 説明                                             |
| --------------------------------- | ------------------------------------------------ |
| `kms_key_deletion_window_in_days` | KMS キー削除待機期間 (日、7-30 の範囲)           |
| `kms_key_enable_rotation`         | KMS キーの自動ローテーションを有効にするかどうか |
| `kms_key_description`             | KMS キーの説明                                   |

### S3 (Lambda 出力用)

| 変数名                                | 説明                                            |
| ------------------------------------- | ----------------------------------------------- |
| `s3_lambda_output_versioning_enabled` | Lambda 出力用 S3 バケットのバージョニング有効化  |
| `s3_lambda_output_lifecycle_rules`    | Lambda 出力用 S3 バケットのライフサイクルルール  |

## 命名規則

| リソース                      | パターン                                      |
| ----------------------------- | --------------------------------------------- |
| S3 Bucket (tfstate)           | `projectl-{env}-terraform-tfstate`            |
| S3 Bucket (Lambda 出力)       | `projectl-{env}-lambda-output`                |
| Subnet (Lambda)               | `projectl-{env}-lambda-{idx}-{az-name}`       |
| Subnet (VPC Endpoint)         | `projectl-{env}-vpc-endpoint-{idx}-{az-name}` |
| SQS Queue                     | `projectl-{env}-sqs-{function-name}`          |
| DLQ                           | `projectl-{env}-sqs-{function-name}-dlq`      |
| Lambda Function               | `projectl-{env}-lambda-{function-name}`       |
| Security Group (Lambda)       | `projectl-{env}-lambda-sg`                    |
| Security Group (SQS Endpoint) | `projectl-{env}-sqs-endpoint-sg`              |
| IAM Role (Lambda)             | `projectl-{env}-lambda-execution-role`        |
| VPC Endpoint (SQS)            | `projectl-{env}-sqs-endpoint`                 |
| KMS Key (SQS)                 | `projectl-{env}-sqs-kms-key`                  |
| KMS Alias (SQS)               | `alias/projectl-{env}-sqs`                    |

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
- **重要**: `terraform apply` 実行後、必ず「Apply 後の手動作業」セクションの手順を実施すること
  - Aurora SG への Lambda SG からのアクセス許可が必須
  - Worker Node SG の egress 設定確認が必要な場合あり

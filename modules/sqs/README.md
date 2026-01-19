# sqs モジュール

SQS キューと Dead Letter Queue を作成します。

## 機能

- SQS メインキュー
- Dead Letter Queue (DLQ、オプション)
- カスタムキューポリシー (オプション)

## 使用方法

### 基本的な使用例

```hcl
module "sqs" {
  source = "../../modules/sqs"

  queue_name = "projectl-dev-processor1"

  # SQS設定
  message_retention_seconds  = 345600 # 4 days
  visibility_timeout_seconds = 30

  # DLQ設定
  create_dlq        = true
  max_receive_count = 3

  tags = {
    Project     = "ProjectL"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### キューポリシー付き

```hcl
module "sqs_with_policy" {
  source = "../../modules/sqs"

  queue_name = "projectl-dev-processor1"

  # カスタムポリシー
  queue_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSendMessage"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:role/MyRole"
        }
        Action   = ["sqs:SendMessage"]
        Resource = "*"
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
| queue_name | SQSキュー名 | string | Yes | - |
| message_retention_seconds | メッセージ保持期間 (秒) | number | No | 345600 |
| visibility_timeout_seconds | 可視性タイムアウト (秒) | number | No | 30 |
| create_dlq | Dead Letter Queueを作成するかどうか | bool | No | true |
| max_receive_count | DLQへ移動する前の最大受信回数 | number | No | 3 |
| dlq_message_retention_seconds | DLQのメッセージ保持期間 (秒) | number | No | 1209600 |
| queue_policy | SQSキューポリシー (JSON文字列) | string | No | null |
| kms_master_key_id | SQSキュー暗号化用のKMS Key ID | string | No | null |
| kms_data_key_reuse_period_seconds | KMSデータキーの再利用期間 (秒) | number | No | 300 |
| tags | リソースに付与するタグ | map(string) | No | {} |

## 出力値

| 名前 | 説明 |
|------|------|
| queue_arn | SQSキューのARN |
| queue_url | SQSキューのURL |
| queue_name | SQSキューの名前 |
| dlq_arn | DLQのARN (create_dlq=falseの場合はnull) |
| dlq_url | DLQのURL (create_dlq=falseの場合はnull) |
| dlq_name | DLQの名前 (create_dlq=falseの場合はnull) |

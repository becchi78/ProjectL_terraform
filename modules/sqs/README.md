# sqs モジュール

SQS Queue、Dead Letter Queue、VPC Endpointを作成します。

## 機能

- SQSメインキュー
- Dead Letter Queue (DLQ)
- SQS VPC Endpoint (オプション)
- キューポリシー (ROSA Pod、Lambda用)
- VPC Endpointポリシー

## 使用方法

```hcl
module "sqs" {
  source = "../../modules/sqs"

  name_prefix   = "projectl-dev"
  function_name = "processor1"
  region        = "ap-northeast-1"

  # SQS設定
  message_retention_seconds  = 345600  # 4 days
  visibility_timeout_seconds = 30
  max_receive_count          = 3

  # VPC Endpoint設定 (最初のキューでのみ作成)
  create_vpc_endpoint     = true
  vpc_id                  = "vpc-xxxxxxxxx"
  sqs_endpoint_subnet_ids = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
  sqs_endpoint_sg_id      = "sg-xxxxxxxxx"

  # アクセス制御
  rosa_pod_iam_role_arn     = "arn:aws:iam::123456789012:role/ProjectL-rosa-pod-role"
  lambda_execution_role_arn = "arn:aws:iam::123456789012:role/projectl-dev-lambda-execution-role"

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
| name_prefix | リソース名のプレフィックス | string | Yes | - |
| function_name | Lambda関数名 (SQSキュー名に使用) | string | Yes | - |
| region | AWSリージョン | string | Yes | - |
| message_retention_seconds | メッセージ保持期間 (秒) | number | No | 345600 |
| visibility_timeout_seconds | 可視性タイムアウト (秒) | number | No | 30 |
| max_receive_count | DLQへ移動する前の最大受信回数 | number | No | 3 |
| dlq_message_retention_seconds | DLQのメッセージ保持期間 (秒) | number | No | 1209600 |
| create_vpc_endpoint | VPC Endpointを作成するかどうか | bool | No | false |
| vpc_id | VPC ID | string | No | "" |
| sqs_endpoint_subnet_ids | SQS Endpoint用サブネットID | list(string) | No | [] |
| sqs_endpoint_sg_id | SQS Endpoint用Security Group ID | string | No | "" |
| rosa_pod_iam_role_arn | ROSA Pod用IAM RoleのARN | string | Yes | - |
| lambda_execution_role_arn | Lambda実行ロールのARN | string | Yes | - |
| tags | リソースに付与するタグ | map(string) | No | {} |

## 出力値

| 名前 | 説明 |
|------|------|
| queue_arn | SQSキューのARN |
| queue_url | SQSキューのURL |
| queue_name | SQSキューの名前 |
| dlq_arn | DLQのARN |
| dlq_url | DLQのURL |
| dlq_name | DLQの名前 |
| vpc_endpoint_id | SQS VPC EndpointのID |
| vpc_endpoint_dns_entry | SQS VPC EndpointのDNSエントリ |

## 注意事項

- VPC Endpointは1つのみ作成 (複数Lambda関数で共有)
- 最初のSQSモジュールで `create_vpc_endpoint = true` を指定
- 2つ目以降は `create_vpc_endpoint = false` を指定

# lambda モジュール

Lambda関数、SQS Event Source Mapping、CloudWatch Log Groupを作成します。

## 機能

- VPC Lambda関数
- SQS Event Source Mapping
- CloudWatch Log Group
- AWS Parameters and Secrets Lambda Extension (オプション)

## 使用方法

```hcl
module "lambda" {
  source = "../../modules/lambda"

  name_prefix   = "projectl-dev"
  function_name = "processor1"
  description   = "SQS processor function"
  region        = "ap-northeast-1"

  # Lambda基本設定
  runtime     = "nodejs20.x"
  handler     = "index.handler"
  memory_size = 128
  timeout     = 30
  source_path = "../../lambda-functions/processor1"

  # VPC設定
  lambda_subnet_ids = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
  lambda_sg_id      = "sg-xxxxxxxxx"

  # IAM
  lambda_execution_role_arn = "arn:aws:iam::123456789012:role/projectl-dev-lambda-execution-role"

  # 環境変数
  aurora_secret_name = "lnkr-dev-aurora"
  additional_environment_variables = {
    LOG_LEVEL = "INFO"
  }

  # SQS Event Source
  sqs_queue_arn           = "arn:aws:sqs:ap-northeast-1:123456789012:projectl-dev-sqs-processor1"
  sqs_batch_size          = 10
  sqs_maximum_concurrency = 10

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
| function_name | Lambda関数名 | string | Yes | - |
| description | Lambda関数の説明 | string | No | "" |
| region | AWSリージョン | string | Yes | - |
| runtime | Lambda Runtime | string | Yes | - |
| handler | Lambda Handler | string | Yes | - |
| memory_size | メモリサイズ (MB) | number | No | 128 |
| timeout | タイムアウト (秒) | number | No | 30 |
| source_path | ソースコードパス | string | Yes | - |
| lambda_subnet_ids | Lambda用サブネットIDのリスト | list(string) | Yes | - |
| lambda_sg_id | Lambda用Security GroupのID | string | Yes | - |
| lambda_execution_role_arn | Lambda実行ロールのARN | string | Yes | - |
| aurora_secret_name | Secrets Manager Secret名 | string | Yes | - |
| additional_environment_variables | 追加の環境変数 | map(string) | No | {} |
| enable_secrets_extension | Secrets Extension有効化 | bool | No | true |
| sqs_queue_arn | SQSキューのARN | string | Yes | - |
| sqs_batch_size | SQSバッチサイズ | number | No | 10 |
| sqs_batching_window_seconds | SQSバッチウィンドウ (秒) | number | No | 0 |
| sqs_maximum_concurrency | SQS最大同時実行数 | number | No | 10 |
| cloudwatch_logs_retention_days | CloudWatch Logs保持期間 (日) | number | No | 30 |
| tags | リソースに付与するタグ | map(string) | No | {} |

## 出力値

| 名前 | 説明 |
|------|------|
| function_arn | Lambda関数のARN |
| function_name | Lambda関数名 |
| function_invoke_arn | Lambda関数のInvoke ARN |
| function_qualified_arn | Lambda関数のQualified ARN |
| function_version | Lambda関数のバージョン |
| log_group_name | CloudWatch Logグループ名 |
| log_group_arn | CloudWatch LogグループのARN |
| event_source_mapping_uuid | SQS Event Source MappingのUUID |

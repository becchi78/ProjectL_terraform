# lambda モジュール

Lambda 関数、CloudWatch Log Group、SQS Event Source Mapping を作成します。

## 機能

- Lambda 関数
- VPC 設定 (オプション)
- CloudWatch Log Group (オプション)
- SQS Event Source Mapping (オプション)
- Lambda Layers サポート

## 使用方法

### 基本的な使用例

```hcl
module "lambda" {
  source = "../../modules/lambda"

  function_name = "projectl-dev-processor1"
  description   = "SQS processor function"

  # Lambda基本設定
  runtime     = "nodejs20.x"
  handler     = "index.handler"
  memory_size = 128
  timeout     = 30
  source_path = "../../lambda-functions/processor1"

  # IAM
  lambda_role_arn = "arn:aws:iam::123456789012:role/projectl-dev-lambda-execution-role"

  # 環境変数
  environment_variables = {
    LOG_LEVEL = "INFO"
    DB_HOST   = "localhost"
  }

  tags = {
    Project     = "ProjectL"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### VPC 内 Lambda + SQS Event Source

```hcl
module "lambda_vpc" {
  source = "../../modules/lambda"

  function_name = "projectl-dev-processor1"
  description   = "SQS processor function in VPC"

  runtime     = "nodejs20.x"
  handler     = "index.handler"
  memory_size = 128
  timeout     = 30
  source_path = "../../lambda-functions/processor1"

  # VPC設定
  vpc_subnet_ids         = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
  vpc_security_group_ids = ["sg-xxxxxxxxx"]

  # IAM
  lambda_role_arn = "arn:aws:iam::123456789012:role/projectl-dev-lambda-execution-role"

  # 環境変数
  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  # Lambda Layers
  layers = [
    "arn:aws:lambda:ap-northeast-1:133490724326:layer:AWS-Parameters-and-Secrets-Lambda-Extension:12"
  ]

  # SQS Event Source
  sqs_event_source = {
    queue_arn            = "arn:aws:sqs:ap-northeast-1:123456789012:projectl-dev-sqs-processor1"
    batch_size           = 10
    batching_window_seconds = 0
    maximum_concurrency  = 10
    enabled              = true
  }

  # CloudWatch Logs
  create_cloudwatch_log_group    = true
  cloudwatch_logs_retention_days = 30

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
| function_name | Lambda関数名 | string | Yes | - |
| description | Lambda関数の説明 | string | No | "" |
| runtime | Lambda Runtime | string | Yes | - |
| handler | Lambda Handler | string | Yes | - |
| memory_size | メモリサイズ (MB) | number | No | 128 |
| timeout | タイムアウト (秒) | number | No | 30 |
| source_path | ソースコードパス | string | Yes | - |
| vpc_subnet_ids | Lambda用サブネットIDのリスト | list(string) | No | [] |
| vpc_security_group_ids | Lambda用Security GroupのIDリスト | list(string) | No | [] |
| lambda_role_arn | Lambda実行ロールのARN | string | Yes | - |
| environment_variables | Lambda関数の環境変数 | map(string) | No | {} |
| layers | Lambda LayerのARNリスト | list(string) | No | [] |
| sqs_event_source | SQSイベントソースの設定 (object) | object | No | null |
| create_cloudwatch_log_group | CloudWatch Log Groupを作成するかどうか | bool | No | true |
| cloudwatch_logs_retention_days | CloudWatch Logsの保持期間 (日) | number | No | 30 |
| tags | リソースに付与するタグ | map(string) | No | {} |

### sqs_event_source オブジェクトの構造

```hcl
{
  queue_arn               = string           # 必須
  batch_size              = optional(number) # デフォルト: 10
  batching_window_seconds = optional(number) # デフォルト: 0
  maximum_concurrency     = optional(number) # デフォルト: null
  enabled                 = optional(bool)   # デフォルト: true
}
```

## 出力値

| 名前 | 説明 |
|------|------|
| function_arn | Lambda関数のARN |
| function_name | Lambda関数名 |
| function_invoke_arn | Lambda関数のInvoke ARN |
| function_qualified_arn | Lambda関数のQualified ARN |
| function_version | Lambda関数のバージョン |
| log_group_name | CloudWatch Logグループ名 (create_cloudwatch_log_group=falseの場合はnull) |
| log_group_arn | CloudWatch LogグループのARN (create_cloudwatch_log_group=falseの場合はnull) |
| event_source_mapping_uuid | SQS Event Source MappingのUUID (sqs_event_source=nullの場合はnull) |

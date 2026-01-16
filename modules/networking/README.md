# networking モジュール

Lambda用サブネットとSQS Endpoint用サブネットを作成します。

## 機能

- Lambda用プライベートサブネット (Multi-AZ)
- SQS VPC Endpoint用プライベートサブネット (Multi-AZ)
- 既存プライベートルートテーブルへの関連付け

## 使用方法

```hcl
module "networking" {
  source = "../../modules/networking"

  vpc_id      = "vpc-xxxxxxxxx"
  name_prefix = "projectl-dev"

  lambda_subnet_cidrs       = ["10.0.10.0/24", "10.0.11.0/24"]
  sqs_endpoint_subnet_cidrs = ["10.0.20.0/24", "10.0.21.0/24"]
  private_route_table_ids   = ["rtb-xxxxxxxx", "rtb-yyyyyyyy"]

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
| vpc_id | VPC ID | string | Yes |
| name_prefix | リソース名のプレフィックス | string | Yes |
| lambda_subnet_cidrs | Lambda用サブネットのCIDRリスト | list(string) | Yes |
| sqs_endpoint_subnet_cidrs | SQS Endpoint用サブネットのCIDRリスト | list(string) | Yes |
| private_route_table_ids | プライベートルートテーブルIDのリスト | list(string) | Yes |
| tags | リソースに付与するタグ | map(string) | No |

## 出力値

| 名前 | 説明 |
|------|------|
| lambda_subnet_ids | Lambda用サブネットのIDリスト |
| lambda_subnet_arns | Lambda用サブネットのARNリスト |
| lambda_subnet_cidrs | Lambda用サブネットのCIDRリスト |
| sqs_endpoint_subnet_ids | SQS Endpoint用サブネットのIDリスト |
| sqs_endpoint_subnet_arns | SQS Endpoint用サブネットのARNリスト |
| sqs_endpoint_subnet_cidrs | SQS Endpoint用サブネットのCIDRリスト |
| availability_zones | 使用しているアベイラビリティゾーン |

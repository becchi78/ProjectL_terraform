# vpc-endpoint モジュール

VPC Endpoint (Interface または Gateway) を作成します。

## 機能

- Interface Endpoint 作成 (SQS, Secrets Manager など)
- Gateway Endpoint 作成 (S3, DynamoDB など)
- VPC Endpoint ポリシー (オプション)

## 使用方法

### Interface Endpoint の例 (SQS)

```hcl
module "sqs_endpoint" {
  source = "../../modules/vpc-endpoint"

  name         = "projectl-dev-sqs-endpoint"
  vpc_id       = "vpc-xxxxxxxxx"
  service_name = "com.amazonaws.ap-northeast-1.sqs"

  vpc_endpoint_type   = "Interface"
  subnet_ids          = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
  security_group_ids  = ["sg-xxxxxxxxx"]
  private_dns_enabled = true

  # VPC Endpointポリシー (オプション)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAll"
        Effect    = "Allow"
        Principal = "*"
        Action    = "*"
        Resource  = "*"
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

### Gateway Endpoint の例 (S3)

```hcl
module "s3_endpoint" {
  source = "../../modules/vpc-endpoint"

  name         = "projectl-dev-s3-endpoint"
  vpc_id       = "vpc-xxxxxxxxx"
  service_name = "com.amazonaws.ap-northeast-1.s3"

  vpc_endpoint_type = "Gateway"
  route_table_ids   = ["rtb-xxxxxxxx", "rtb-yyyyyyyy"]

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
| name | VPC Endpointの名前 (Nameタグに使用) | string | Yes | - |
| vpc_id | VPC ID | string | Yes | - |
| service_name | AWSサービス名 (例: com.amazonaws.ap-northeast-1.sqs) | string | Yes | - |
| vpc_endpoint_type | VPC Endpointのタイプ (Interface または Gateway) | string | No | Interface |
| subnet_ids | Interface Endpoint用サブネットIDのリスト | list(string) | No | [] |
| security_group_ids | Interface Endpoint用Security GroupのIDリスト | list(string) | No | [] |
| private_dns_enabled | プライベートDNSを有効化するかどうか (Interface Endpointのみ) | bool | No | true |
| route_table_ids | Gateway Endpoint用ルートテーブルIDのリスト | list(string) | No | [] |
| policy | VPC Endpointポリシー (JSON文字列) | string | No | null |
| tags | リソースに付与するタグ | map(string) | No | {} |

## 出力値

| 名前 | 説明 |
|------|------|
| id | VPC EndpointのID |
| arn | VPC EndpointのARN |
| dns_entry | VPC EndpointのDNSエントリ (Interface Endpointのみ) |
| network_interface_ids | VPC EndpointのネットワークインターフェースID (Interface Endpointのみ) |
| state | VPC Endpointの状態 |

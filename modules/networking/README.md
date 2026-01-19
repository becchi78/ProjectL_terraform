# networking モジュール

プライベートサブネットを作成します。

## 機能

- プライベートサブネット作成 (Multi-AZ)
- 柔軟なサブネット定義 (map形式)
- ルートテーブルへの関連付け (オプション)

## 使用方法

```hcl
module "networking" {
  source = "../../modules/networking"

  vpc_id      = "vpc-xxxxxxxxx"
  name_prefix = "projectl-dev"
  az_count    = 2

  # 用途別にサブネットを定義
  subnets = {
    "lambda-0" = {
      cidr_block = "10.0.100.0/24"
      az_index   = 0
      tags       = { Type = "Lambda" }
    }
    "lambda-1" = {
      cidr_block = "10.0.101.0/24"
      az_index   = 1
      tags       = { Type = "Lambda" }
    }
    "endpoint-0" = {
      cidr_block = "10.0.110.0/24"
      az_index   = 0
      tags       = { Type = "Endpoint" }
    }
    "endpoint-1" = {
      cidr_block = "10.0.111.0/24"
      az_index   = 1
      tags       = { Type = "Endpoint" }
    }
  }

  # ルートテーブル関連付け (オプション)
  route_table_id = "rtb-xxxxxxxx"

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
| vpc_id | VPC ID | string | Yes | - |
| name_prefix | リソース名のプレフィックス | string | Yes | - |
| az_count | 使用するアベイラビリティゾーンの数 | number | No | 2 |
| subnets | サブネット定義のマップ | map(object) | No | {} |
| route_table_id | 関連付けるルートテーブルID | string | No | "" |
| tags | リソースに付与するタグ | map(string) | No | {} |

## 出力値

| 名前 | 説明 |
|------|------|
| subnet_ids | 作成されたサブネットのIDマップ |
| subnet_arns | 作成されたサブネットのARNマップ |
| subnet_cidrs | 作成されたサブネットのCIDRマップ |
| availability_zones | 使用しているアベイラビリティゾーン |

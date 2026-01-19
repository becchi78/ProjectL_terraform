# security-group モジュール

Security Group を作成します。

## 機能

- Security Group 作成
- Ingress/Egress ルール設定
- 循環参照を回避する追加ルール機能

## 使用方法

### 基本的な使用例

```hcl
module "lambda_sg" {
  source = "../../modules/security-group"

  name        = "projectl-dev-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = "vpc-xxxxxxxxx"

  egress_with_cidr_blocks = [
    {
      description = "HTTPS to internet"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Project     = "ProjectL"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### Security Group ID を参照する例

```hcl
module "app_sg" {
  source = "../../modules/security-group"

  name        = "projectl-dev-app-sg"
  description = "Application security group"
  vpc_id      = "vpc-xxxxxxxxx"

  ingress_with_source_security_group_id = [
    {
      description              = "From ALB"
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      source_security_group_id = "sg-xxxxxxxxx"
    }
  ]

  egress_with_source_security_group_id = [
    {
      description              = "To database"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = "sg-yyyyyyyy"
    }
  ]

  tags = {
    Project     = "ProjectL"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### 循環参照を回避する追加ルール

```hcl
module "sg_a" {
  source = "../../modules/security-group"

  name   = "projectl-dev-sg-a"
  vpc_id = "vpc-xxxxxxxxx"

  # 初期ルール (循環参照しないもののみ)
  egress_with_cidr_blocks = [
    {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  # 追加ルール (モジュール作成後に参照を追加)
  additional_egress_rules = {
    "to-sg-b" = {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.sg_b.security_group_id
      description              = "To SG B"
    }
  }

  tags = {
    Project     = "ProjectL"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

module "sg_b" {
  source = "../../modules/security-group"

  name   = "projectl-dev-sg-b"
  vpc_id = "vpc-xxxxxxxxx"

  # SG Aからのingressを追加ルールで設定
  additional_ingress_rules = {
    "from-sg-a" = {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.sg_a.security_group_id
      description              = "From SG A"
    }
  }

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
| name | Security Groupの名前 | string | Yes | - |
| description | Security Groupの説明 | string | No | "" |
| vpc_id | VPC ID | string | Yes | - |
| ingress_with_source_security_group_id | ソースSecurity Groupを指定するIngressルールのリスト | list(any) | No | [] |
| ingress_with_cidr_blocks | CIDRブロックを指定するIngressルールのリスト | list(any) | No | [] |
| ingress_with_self | 自己参照Ingressルールのリスト | list(any) | No | [] |
| egress_with_source_security_group_id | ソースSecurity Groupを指定するEgressルールのリスト | list(any) | No | [] |
| egress_with_cidr_blocks | CIDRブロックを指定するEgressルールのリスト | list(any) | No | [] |
| additional_ingress_rules | 追加のIngressルールのマップ (循環参照回避用) | map(any) | No | {} |
| additional_egress_rules | 追加のEgressルールのマップ (循環参照回避用) | map(any) | No | {} |
| tags | リソースに付与するタグ | map(string) | No | {} |

## 出力値

| 名前 | 説明 |
|------|------|
| security_group_id | Security GroupのID |
| security_group_arn | Security GroupのARN |
| security_group_name | Security Groupの名前 |

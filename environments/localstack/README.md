# LocalStack環境

ローカル開発用のLocalStack環境です。

## 前提条件

- Docker
- LocalStack (`pip install localstack` または Docker Compose)
- AWS CLI (LocalStack用設定済み)

## LocalStackの起動

```bash
# Docker Composeを使用する場合
docker-compose up -d

# または localstack CLI を使用
localstack start
```

## 使用方法

```bash
cd environments/localstack

# terraform.tfvarsを作成
cp terraform.tfvars.example terraform.tfvars

# 初期化
terraform init

# プラン確認
terraform plan

# 適用
terraform apply
```

## LocalStack用AWS CLI設定

```bash
# 環境変数を設定
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=ap-northeast-1

# エンドポイントを指定してコマンド実行
aws --endpoint-url=http://localhost:4566 sqs list-queues
aws --endpoint-url=http://localhost:4566 lambda list-functions
```

## 注意事項

- VPC関連機能はLocalStackでは限定的なため、簡略化されたリソース定義を使用
- Security Groups、VPC Endpoints、サブネットは作成されません
- Lambda関数はVPC外で動作します
- 本番環境との動作の違いに注意してください

## トラブルシューティング

### LocalStackが起動しない

```bash
docker logs localstack
```

### Terraformがエラーを返す

LocalStackのログを確認:
```bash
docker logs -f localstack
```

### Lambda関数がデプロイできない

ソースコードディレクトリを確認:
```bash
ls -la ../../lambda-functions/
```

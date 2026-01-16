# Terraform コマンド

- `terraform init`: Terraform を初期化 (`-upgrade`でプロバイダー更新)
- `terraform fmt -recursive`: ディレクトリツリー内の全.tf ファイルをフォーマット
- `terraform validate`: 設定の構文を検証
- `terraform plan -out=plan.tfplan`: 実行プランを作成・保存
- `terraform apply plan.tfplan`: 保存したプランを適用
- `terraform destroy`: 管理している全リソースを削除
- `terraform state list`: state 内の全リソースをリスト表示
- `terraform state show <resource>`: リソースの詳細な state 情報を表示

# Terraform バージョン要件

- Terraform: 1.14.3
- AWS Provider: 6.27.0
- 本番環境では必ずモジュールバージョンを固定する

# コーディング規約

## HCL フォーマット

- コミット前に`terraform fmt`を実行
- インデントは 2 スペース
- リソースブロック間に 1 行の空行を入れる
- 関連するリソースはコメントでグループ化

## 命名規則

- 小文字とハイフンを使用: `projectL-dev-lambda-processor`
- パターン: `{プロジェクト名}-{環境}-{リソースタイプ}-{説明}`
- 説明的だが簡潔に
- 広く理解されている略語以外は使用しない

## リソースの整理

- 可能な限り 1 ファイルに 1 リソースタイプ (例: `sqs.tf`, `lambda.tf`)
- 全ての data source は`data.tf`にまとめる
- 入力変数は`variables.tf`に
- 出力値は`outputs.tf`に
- ローカル値は`locals.tf`に

## count vs for_each の使い分け

- `for_each`を使用する場合:
  - リソースごとに異なる設定が必要
  - キーでリソースを参照する必要がある
  - map/set に基づいた動的リソース作成
- `count`を使用する場合:
  - 同一のリソースを複数作成
  - シンプルな 0 または 1 の条件付き作成 (`count = var.enabled ? 1 : 0`)

## コメント

- 複雑なロジックや自明でない判断にはコメントを追加
- 「何を」ではなく「なぜ」を説明 (コードが「何を」を示す)
- 1 行コメントは`#`を使用
- 長い説明は複数行形式で:

```hcl
# このSecurity Groupが複数のソースからのアクセスを許可している理由:
# - Worker NodeからSQSへメッセージ送信が必要
# - Lambda関数がSQSからポーリングする必要がある
# - コスト最適化のため両方とも同じVPCエンドポイントを使用
```

# セキュリティのベストプラクティス

## 機密データ

- シークレット、パスワード、API キーをハードコードしない
- AWS Secrets Manager または Parameter Store を使用するが、手動設定とする
- 機密変数には`sensitive = true`を設定
- 実際の値を含む`.tfvars`ファイルはコミットしない (`.tfvars.example`を使用)

## IAM ポリシー

- 最小権限の原則に従う
- 可能な限り`*`ではなく具体的なリソース ARN を使用
- 各権限が必要な理由をドキュメント化
- 適用前に IAM ポリシーをレビュー

## Security Groups

- ingress/egress ルールを明示的に記述
- 可能な限り CIDR ブロックではなくセキュリティグループ ID を参照
- 各ルールの目的をドキュメント化
- 絶対に必要でない限り`0.0.0.0/0`は避ける

# タグ戦略

全てのリソースに以下のタグを必須で付与:

```hcl
tags = {
  Project     = "ProjectL"
  Environment = var.environment
  ManagedBy   = "Terraform"
}
```

コスト追跡や組織管理のため、必要に応じて追加のタグを付与。

# ワークフロー

## 開発プロセス

1. `main`から feature ブランチを作成
2. ローカルで Terraform コードを開発
3. コードをフォーマット
4. 説明的なコミットメッセージで変更をコミット
5. プッシュして Pull Request を作成
6. チームメンバーによるコードレビュー
7. dev 環境でテスト (踏み台サーバ)
8. 承認後に main へマージ

## デプロイプロセス

1. 踏み台サーバへ SSH 接続 (dev/stg/prod)
2. 最新コードを pull
3. `terraform plan`を実行し、慎重にレビュー
4. 以下を確認:
   - 予期しないリソース削除
   - Security Group の変更
   - IAM ポリシーの変更
   - リソースの置き換え (destroy + create)
5. plan 承認後にのみ`terraform apply`を実行
6. AWS コンソールでリソースを確認
7. アプリケーション機能をテスト

## 踏み台サーバでの検証

- `terraform validate`は踏み台サーバでのみ実行可能
- 本番適用前に plan と validate を実施
- レビュー/承認のために plan 出力を保存

# オフライン環境 (踏み台サーバ)

## 重要ポイント

- 踏み台サーバ (dev/stg/prod) はインターネットアクセスが制限されている
- Terraform バイナリとモジュールは`terraform-local/`に事前ダウンロード済み
- モジュール参照は相対パスを使用
- 例: `source = "../../../terraform-local/modules/terraform-aws-sqs-5.1.0"`

## モジュール参照

- 公式モジュールは`terraform-local/modules/`にダウンロード済み
- 常にローカルの相対パスを使用
- レジストリソースは使用しない (例: `terraform-aws-modules/sqs/aws`)

# State 管理

## Backend 設定

- dev/stg/prod では S3 backend を使用
- localstack では local backend を使用
- 環境ごとに state バケット: `ProjectL-{env}-terraform-tfstate`
- state バケットでバージョニングを有効化
- 暗号化を有効化 (AES256 または KMS)

## State 操作

- state ファイルを手動で編集しない
- state 操作には`terraform state`コマンドを使用
- 大きな変更前には必ず state をバックアップ
- DynamoDB ロックは使用しない (環境ごとに踏み台サーバは 1 台のみ)

# 変数のベストプラクティス

## 変数のバリデーション

重要な変数にはバリデーションルールを追加:

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "stg", "prod", "localstack"], var.environment)
    error_message = "Environmentはdev, stg, prod, localstackのいずれかである必要があります。"
  }
}
```

## 変数のドキュメント化

- 変数には必ず`description`を追加
- `type`を明示的に指定
- 適切な場合は`default`を提供
- 期待される値を示すために`.tfvars.example`を使用

# チーム開発

## コードレビューチェックリスト

- [ ] 命名規則に従っているか
- [ ] 全リソースに適切にタグ付けされているか
- [ ] ハードコードされたシークレットや機密データがないか
- [ ] IAM ポリシーが最小権限の原則に従っているか
- [ ] Security Group ルールがドキュメント化されているか
- [ ] 変数に description と type が設定されているか
- [ ] モジュールバージョンが固定されているか
- [ ] 複雑なロジックにコメントがあるか
- [ ] plan 出力で予期しない変更がないかレビュー済みか

## Git 運用

- 説明的なコミットメッセージを使用
- コミットに issue 番号を記載
- コミットは焦点を絞り、アトミックに保つ
- `.tfstate`ファイルはコミットしない
- 機密ファイルには`.gitignore`を使用

## コミュニケーション

- PR コメントで判断をドキュメント化
- レビューのために plan 出力を共有
- 大きなインフラ変更は実装前に議論
- 共有環境へのデプロイ時はチームに更新を共有

# トラブルシューティング

## よくある問題

- **モジュールが見つからない**: オフライン環境での相対パスを確認
- **プロバイダーバージョンの不一致**: `terraform-local/`に正しいバージョンがあるか確認
- **State ロックエラー**: 該当なし (DynamoDB ロック未使用)
- **認証エラー**: 踏み台サーバの AWS 認証情報を確認

## ヘルプを得る

- Terraform ドキュメントを確認: https://developer.hashicorp.com/terraform/docs
- `terraform-local/modules/`のモジュールドキュメントをレビュー
- PR またはチャットでチームメンバーに質問
- 助けを求める際は plan 出力を共有

# 重要な注意事項

- これは 5 人チームのプロジェクト - 変更は明確にコミュニケーション
- 踏み台サーバでのデプロイのみ - まず localstack でローカルテスト
- 適用前に必ず plan 出力をレビュー
- 全リソースに一貫したタグ付け
- 自明でない判断はドキュメント化
- モジュールと変数は環境間で再利用可能に保つ

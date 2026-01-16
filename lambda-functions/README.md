# Lambda Functions

このディレクトリはGit Submoduleとして管理されています。
実際のソースコードは別リポジトリ (`https://github.com/your-org/ProjectL-lambda-functions.git`) から取得されます。

## 構成

```
lambda-functions/
├── processor1/          # Node.js Lambda関数
│   ├── index.js
│   └── package.json
└── processor2/          # Python Lambda関数
    ├── lambda_function.py
    └── requirements.txt
```

## processor1 (Node.js)

SQSメッセージを受信してAuroraに処理結果を保存するNode.js関数。

- **Runtime**: nodejs20.x
- **Handler**: index.handler

## processor2 (Python)

SQSメッセージを受信してAuroraに処理結果を保存するPython関数。

- **Runtime**: python3.12
- **Handler**: lambda_function.lambda_handler

## ローカル開発

### Node.js (processor1)

```bash
cd processor1
npm install
node -e "const h = require('./index'); h.handler({Records:[]})"
```

### Python (processor2)

```bash
cd processor2
pip install -r requirements.txt
python -c "from lambda_function import lambda_handler; lambda_handler({'Records':[]}, None)"
```

## 環境変数

| 変数名 | 説明 |
|--------|------|
| AURORA_SECRET_NAME | Aurora接続情報を格納したSecrets Manager Secret名 |

## 注意事項

- このディレクトリ内のファイルはプレースホルダーです
- 実際のプロジェクトでは、Git Submoduleとして別リポジトリから取得してください
- Lambda Layer は現在使用していません

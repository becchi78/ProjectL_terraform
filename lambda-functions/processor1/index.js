/**
 * SQS Processor 1 (Node.js)
 * SQSメッセージを受信してAuroraに処理結果を保存する
 */

const {
  SecretsManagerClient,
  GetSecretValueCommand,
} = require("@aws-sdk/client-secrets-manager");

// Secrets Manager クライアント
const secretsManager = new SecretsManagerClient();

// Aurora接続情報をキャッシュ
let dbCredentials = null;

/**
 * Secrets ManagerからAurora接続情報を取得
 */
async function getDbCredentials() {
  if (dbCredentials) {
    return dbCredentials;
  }

  const secretName = process.env.AURORA_SECRET_NAME;
  if (!secretName) {
    throw new Error("AURORA_SECRET_NAME environment variable is not set");
  }

  const command = new GetSecretValueCommand({ SecretId: secretName });
  const response = await secretsManager.send(command);

  dbCredentials = JSON.parse(response.SecretString);
  return dbCredentials;
}

/**
 * SQSメッセージを処理
 */
async function processMessage(record) {
  const body = JSON.parse(record.body);
  console.log("Processing message:", JSON.stringify(body));

  // TODO: Aurora接続処理を実装
  // const credentials = await getDbCredentials();
  // const connection = await createConnection(credentials);
  // await connection.execute(...);

  return {
    messageId: record.messageId,
    status: "processed",
  };
}

/**
 * Lambda Handler
 */
exports.handler = async (event) => {
  console.log("Received event:", JSON.stringify(event));

  const results = [];
  const batchItemFailures = [];

  for (const record of event.Records) {
    try {
      const result = await processMessage(record);
      results.push(result);
    } catch (error) {
      console.error(`Error processing message ${record.messageId}:`, error);
      batchItemFailures.push({
        itemIdentifier: record.messageId,
      });
    }
  }

  console.log(`Processed ${results.length} messages successfully`);
  if (batchItemFailures.length > 0) {
    console.log(`Failed to process ${batchItemFailures.length} messages`);
  }

  // 部分的なバッチ失敗をサポート
  return {
    batchItemFailures,
  };
};

"""
SQS Processor 2 (Python)
SQSメッセージを受信してAuroraに処理結果を保存する
"""

import json
import os
import boto3
from botocore.exceptions import ClientError

# Secrets Manager クライアント
secrets_manager = boto3.client("secretsmanager")

# Aurora接続情報をキャッシュ
db_credentials = None


def get_db_credentials():
    """Secrets ManagerからAurora接続情報を取得"""
    global db_credentials

    if db_credentials:
        return db_credentials

    secret_name = os.environ.get("AURORA_SECRET_NAME")
    if not secret_name:
        raise ValueError("AURORA_SECRET_NAME environment variable is not set")

    try:
        response = secrets_manager.get_secret_value(SecretId=secret_name)
        db_credentials = json.loads(response["SecretString"])
        return db_credentials
    except ClientError as e:
        raise Exception(f"Failed to retrieve secret: {e}")


def process_message(record):
    """SQSメッセージを処理"""
    body = json.loads(record["body"])
    print(f"Processing message: {json.dumps(body)}")

    # TODO: Aurora接続処理を実装
    # credentials = get_db_credentials()
    # connection = create_connection(credentials)
    # cursor = connection.cursor()
    # cursor.execute(...)

    return {"messageId": record["messageId"], "status": "processed"}


def lambda_handler(event, context):
    """Lambda Handler"""
    print(f"Received event: {json.dumps(event)}")

    results = []
    batch_item_failures = []

    for record in event.get("Records", []):
        try:
            result = process_message(record)
            results.append(result)
        except Exception as e:
            print(f"Error processing message {record['messageId']}: {e}")
            batch_item_failures.append({"itemIdentifier": record["messageId"]})

    print(f"Processed {len(results)} messages successfully")
    if batch_item_failures:
        print(f"Failed to process {len(batch_item_failures)} messages")

    # 部分的なバッチ失敗をサポート
    return {"batchItemFailures": batch_item_failures}

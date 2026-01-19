# -----------------------------------------------------------------------------
# メインリソース定義 (LocalStack用簡略版)
# LocalStackはVPC関連機能が制限されているため、SQSとLambdaのみ作成
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# S3 Bucket (Lambda出力用 - LocalStack用簡略版)
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "lambda_output" {
  bucket = "${local.name_prefix}-lambda-output"

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "lambda_output" {
  bucket = aws_s3_bucket.lambda_output.id
  versioning_configuration {
    status = "Disabled"
  }
}

# -----------------------------------------------------------------------------
# IAM Role (LocalStack用簡略版)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "lambda_execution" {
  name = "${local.name_prefix}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "lambda_execution" {
  name = "${local.name_prefix}-lambda-execution-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# SQS Queues (メインキュー + DLQ)
# -----------------------------------------------------------------------------

resource "aws_sqs_queue" "dlq" {
  for_each = var.lambda_functions

  name                      = "${local.name_prefix}-sqs-${each.key}-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = local.common_tags
}

resource "aws_sqs_queue" "main" {
  for_each = var.lambda_functions

  name                       = "${local.name_prefix}-sqs-${each.key}"
  message_retention_seconds  = var.sqs_message_retention_seconds
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = var.sqs_max_receive_count
  })

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Lambda Functions
# -----------------------------------------------------------------------------

data "archive_file" "lambda" {
  for_each = var.lambda_functions

  type        = "zip"
  source_dir  = "${path.root}/../../${each.value.source_dir}"
  output_path = "${path.root}/.terraform/tmp/${each.key}.zip"
}

resource "aws_lambda_function" "main" {
  for_each = var.lambda_functions

  function_name = "${local.name_prefix}-lambda-${each.key}"
  description   = each.value.description
  role          = aws_iam_role.lambda_execution.arn

  filename         = data.archive_file.lambda[each.key].output_path
  source_code_hash = data.archive_file.lambda[each.key].output_base64sha256

  runtime     = each.value.runtime
  handler     = each.value.handler
  memory_size = each.value.memory_size
  timeout     = each.value.timeout

  environment {
    variables = {
      SECRETS_NAME          = "localstack-lambda-secrets"
      S3_OUTPUT_BUCKET_NAME = aws_s3_bucket.lambda_output.bucket
    }
  }

  tags = local.common_tags
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "lambda" {
  for_each = var.lambda_functions

  name              = "/aws/lambda/${local.name_prefix}-lambda-${each.key}"
  retention_in_days = 7

  tags = local.common_tags
}

# SQS Event Source Mapping
resource "aws_lambda_event_source_mapping" "sqs" {
  for_each = var.lambda_functions

  event_source_arn = aws_sqs_queue.main[each.key].arn
  function_name    = aws_lambda_function.main[each.key].arn
  batch_size       = var.sqs_batch_size
  enabled          = true
}

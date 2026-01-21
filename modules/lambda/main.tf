# -----------------------------------------------------------------------------
# Lambda Function
# -----------------------------------------------------------------------------

module "lambda" {
  source = "../../terraform-local/modules/lambda_function"

  function_name = var.function_name
  description   = var.description
  handler       = var.handler
  runtime       = var.runtime
  memory_size   = var.memory_size
  timeout       = var.timeout

  # ソースコード
  source_path = var.source_path

  # VPC設定 (オプション)
  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids

  # IAMロール
  create_role = false
  lambda_role = var.lambda_role_arn

  # 環境変数
  environment_variables = var.environment_variables

  # Lambda Layers
  layers = var.layers

  # CloudWatch Logs
  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_days

  tags = var.tags
}

# SQS Event Source Mapping (オプション)
resource "aws_lambda_event_source_mapping" "sqs" {
  count = var.sqs_event_source != null ? 1 : 0

  event_source_arn                   = var.sqs_event_source.queue_arn
  function_name                      = module.lambda.lambda_function_arn
  batch_size                         = lookup(var.sqs_event_source, "batch_size", 10)
  maximum_batching_window_in_seconds = lookup(var.sqs_event_source, "batching_window_seconds", 0)
  enabled                            = lookup(var.sqs_event_source, "enabled", true)

  dynamic "scaling_config" {
    for_each = lookup(var.sqs_event_source, "maximum_concurrency", null) != null ? [1] : []
    content {
      maximum_concurrency = var.sqs_event_source.maximum_concurrency
    }
  }
}

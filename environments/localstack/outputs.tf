# -----------------------------------------------------------------------------
# 出力値 (LocalStack用)
# -----------------------------------------------------------------------------

# SQS
output "sqs_queue_urls" {
  description = "SQSキューのURLマップ"
  value       = { for k, v in aws_sqs_queue.main : k => v.url }
}

output "sqs_queue_arns" {
  description = "SQSキューのARNマップ"
  value       = { for k, v in aws_sqs_queue.main : k => v.arn }
}

output "dlq_urls" {
  description = "DLQのURLマップ"
  value       = { for k, v in aws_sqs_queue.dlq : k => v.url }
}

# Lambda
output "lambda_function_arns" {
  description = "Lambda関数のARNマップ"
  value       = { for k, v in aws_lambda_function.main : k => v.arn }
}

output "lambda_function_names" {
  description = "Lambda関数名のマップ"
  value       = { for k, v in aws_lambda_function.main : k => v.function_name }
}

output "lambda_log_group_names" {
  description = "Lambda CloudWatch Logグループ名のマップ"
  value       = { for k, v in aws_cloudwatch_log_group.lambda : k => v.name }
}

# IAM
output "lambda_execution_role_arn" {
  description = "Lambda実行ロールのARN"
  value       = aws_iam_role.lambda_execution.arn
}

# S3 (Lambda出力用)
output "s3_lambda_output_bucket_name" {
  description = "Lambda出力用S3バケット名"
  value       = aws_s3_bucket.lambda_output.bucket
}

output "s3_lambda_output_bucket_arn" {
  description = "Lambda出力用S3バケットのARN"
  value       = aws_s3_bucket.lambda_output.arn
}

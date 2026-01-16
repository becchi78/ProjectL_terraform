# -----------------------------------------------------------------------------
# 出力値
# -----------------------------------------------------------------------------

# Networking
output "lambda_subnet_ids" {
  description = "Lambda用サブネットのIDリスト"
  value       = values(module.lambda_subnets.subnet_ids)
}

output "vpc_endpoint_subnet_ids" {
  description = "VPC Endpoint用サブネットのIDリスト"
  value       = values(module.vpc_endpoint_subnets.subnet_ids)
}

# Security
output "lambda_sg_id" {
  description = "Lambda Security GroupのID"
  value       = module.lambda_sg.security_group_id
}

output "sqs_endpoint_sg_id" {
  description = "SQS Endpoint Security GroupのID"
  value       = module.sqs_endpoint_sg.security_group_id
}

output "lambda_execution_role_arn" {
  description = "Lambda実行ロールのARN"
  value       = module.lambda_execution_role.role_arn
}

# SQS
output "sqs_queue_urls" {
  description = "SQSキューのURLマップ"
  value       = { for k, v in module.sqs : k => v.queue_url }
}

output "sqs_queue_arns" {
  description = "SQSキューのARNマップ"
  value       = { for k, v in module.sqs : k => v.queue_arn }
}

output "dlq_urls" {
  description = "DLQのURLマップ"
  value       = { for k, v in module.sqs : k => v.dlq_url }
}

# VPC Endpoint
output "sqs_vpc_endpoint_id" {
  description = "SQS VPC EndpointのID"
  value       = module.sqs_vpc_endpoint.id
}

# Lambda
output "lambda_function_arns" {
  description = "Lambda関数のARNマップ"
  value       = { for k, v in module.lambda : k => v.function_arn }
}

output "lambda_function_names" {
  description = "Lambda関数名のマップ"
  value       = { for k, v in module.lambda : k => v.function_name }
}

output "lambda_log_group_names" {
  description = "Lambda CloudWatch Logグループ名のマップ"
  value       = { for k, v in module.lambda : k => v.log_group_name }
}

# S3 (Lambda出力用)
output "s3_lambda_output_bucket_name" {
  description = "Lambda出力用S3バケット名"
  value       = module.s3_lambda_output.bucket_name
}

output "s3_lambda_output_bucket_arn" {
  description = "Lambda出力用S3バケットのARN"
  value       = module.s3_lambda_output.bucket_arn
}

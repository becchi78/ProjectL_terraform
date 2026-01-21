# -----------------------------------------------------------------------------
# 出力値
# -----------------------------------------------------------------------------

output "function_arn" {
  description = "Lambda関数のARN"
  value       = module.lambda.lambda_function_arn
}

output "function_name" {
  description = "Lambda関数名"
  value       = module.lambda.lambda_function_name
}

output "function_invoke_arn" {
  description = "Lambda関数のInvoke ARN"
  value       = module.lambda.lambda_function_invoke_arn
}

output "function_qualified_arn" {
  description = "Lambda関数のQualified ARN"
  value       = module.lambda.lambda_function_qualified_arn
}

output "function_version" {
  description = "Lambda関数のバージョン"
  value       = module.lambda.lambda_function_version
}

output "log_group_name" {
  description = "CloudWatch Logグループ名"
  value       = module.lambda.lambda_cloudwatch_log_group_name
}

output "log_group_arn" {
  description = "CloudWatch LogグループのARN"
  value       = module.lambda.lambda_cloudwatch_log_group_arn
}

output "event_source_mapping_uuid" {
  description = "SQS Event Source MappingのUUID"
  value       = var.sqs_event_source != null ? aws_lambda_event_source_mapping.sqs[0].uuid : null
}

# -----------------------------------------------------------------------------
# 出力値
# -----------------------------------------------------------------------------

# メインキュー
output "queue_arn" {
  description = "SQSキューのARN"
  value       = module.sqs.queue_arn
}

output "queue_url" {
  description = "SQSキューのURL"
  value       = module.sqs.queue_url
}

output "queue_name" {
  description = "SQSキューの名前"
  value       = module.sqs.queue_name
}

# Dead Letter Queue
output "dlq_arn" {
  description = "DLQのARN"
  value       = var.create_dlq ? module.dlq[0].queue_arn : null
}

output "dlq_url" {
  description = "DLQのURL"
  value       = var.create_dlq ? module.dlq[0].queue_url : null
}

output "dlq_name" {
  description = "DLQの名前"
  value       = var.create_dlq ? module.dlq[0].queue_name : null
}

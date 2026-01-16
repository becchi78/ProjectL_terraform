# -----------------------------------------------------------------------------
# SQS Queue + DLQ
# -----------------------------------------------------------------------------

# Dead Letter Queue (オプション)
module "dlq" {
  source = "../../../terraform-local/modules/sqs"
  count  = var.create_dlq ? 1 : 0

  name = "${var.queue_name}-dlq"

  message_retention_seconds = var.dlq_message_retention_seconds

  tags = var.tags
}

# メインキュー
module "sqs" {
  source = "../../../terraform-local/modules/sqs"

  name = var.queue_name

  message_retention_seconds  = var.message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds

  # Dead Letter Queue設定 (オプション)
  redrive_policy = var.create_dlq ? jsonencode({
    deadLetterTargetArn = module.dlq[0].queue_arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  tags = var.tags
}

# SQS Queue ポリシー (オプション)
resource "aws_sqs_queue_policy" "main" {
  count     = var.queue_policy != null ? 1 : 0
  queue_url = module.sqs.queue_url

  policy = var.queue_policy
}

# -----------------------------------------------------------------------------
# メインリソース定義
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Networking - Lambda用サブネット
# -----------------------------------------------------------------------------

module "lambda_subnets" {
  source = "../../modules/networking"

  vpc_id      = var.vpc_id
  name_prefix = local.name_prefix
  az_count    = 3

  subnets = {
    for idx, cidr in var.lambda_subnet_cidrs : "lambda-${idx}" => {
      cidr_block = cidr
      az_index   = idx
      tags       = { Type = "Lambda" }
    }
  }

  route_table_id = var.private_route_table_ids[0]

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Networking - VPC Endpoint用サブネット
# -----------------------------------------------------------------------------

module "vpc_endpoint_subnets" {
  source = "../../modules/networking"

  vpc_id      = var.vpc_id
  name_prefix = local.name_prefix
  az_count    = 3

  subnets = {
    for idx, cidr in var.vpc_endpoint_subnet_cidrs : "vpc-endpoint-${idx}" => {
      cidr_block = cidr
      az_index   = idx
      tags       = { Type = "VPC-Endpoint" }
    }
  }

  route_table_id = var.private_route_table_ids[0]

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Security Group - Lambda用
# -----------------------------------------------------------------------------

module "lambda_sg" {
  source = "../../modules/security-group"

  name        = "${local.name_prefix}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = var.vpc_id

  egress_with_source_security_group_id = [
    {
      description              = "Aurora DB access"
      from_port                = var.aurora_port
      to_port                  = var.aurora_port
      protocol                 = "tcp"
      source_security_group_id = var.aurora_sg_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      description = "Secrets Manager VPC Endpoint access"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.vpc_cidr
    }
  ]

  # SQS/CloudWatch Logs Endpoint SGへのEgressは後で追加 (循環参照回避)
  additional_egress_rules = {
    "to-sqs-endpoint" = {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.sqs_endpoint_sg.security_group_id
      description              = "SQS VPC Endpoint access"
    }
    "to-cloudwatch-logs-endpoint" = {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.cloudwatch_logs_endpoint_sg.security_group_id
      description              = "CloudWatch Logs VPC Endpoint access"
    }
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Security Group - SQS VPC Endpoint用
# -----------------------------------------------------------------------------

module "sqs_endpoint_sg" {
  source = "../../modules/security-group"

  name        = "${local.name_prefix}-sqs-endpoint-sg"
  description = "Security group for SQS VPC Endpoint"
  vpc_id      = var.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "ROSA Worker Node to SQS Endpoint"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = var.worker_node_sg_id
    }
  ]

  # Lambda SGからのIngressは後で追加 (循環参照回避)
  additional_ingress_rules = {
    "from-lambda" = {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.lambda_sg.security_group_id
      description              = "Lambda to SQS Endpoint"
    }
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# IAM Role - Lambda実行ロール
# -----------------------------------------------------------------------------

module "lambda_execution_role" {
  source = "../../modules/iam-role"

  role_name = "${local.name_prefix}-lambda-execution-role"

  trusted_role_services = ["lambda.amazonaws.com"]

  role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]

  inline_policy_statements = [
    {
      sid = "SecretsManagerAccess"
      actions = [
        "secretsmanager:GetSecretValue"
      ]
      resources = ["arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:projectl-${var.environment}-*"]
    },
    {
      sid = "SQSAccess"
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      resources = ["arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${local.name_prefix}-sqs-*"]
    },
    {
      sid = "S3Access"
      actions = [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      resources = [
        module.s3_lambda_output.bucket_arn,
        "${module.s3_lambda_output.bucket_arn}/*"
      ]
    },
    {
      sid = "CloudWatchLogsAccess"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.name_prefix}-lambda-*"]
    },
    {
      sid = "KMSDecryptForSQS"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]
      resources = [aws_kms_key.sqs.arn]
    }
  ]

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# KMS Key (SQS暗号化用)
# -----------------------------------------------------------------------------

resource "aws_kms_key" "sqs" {
  description             = var.kms_key_description
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_enable_rotation

  policy = templatefile("${path.module}/policies/projectl-sqs-kms-key-policy.json", {
    account_id = data.aws_caller_identity.current.account_id
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sqs-kms-key"
  })
}

# -----------------------------------------------------------------------------
# S3 Bucket (Lambda出力用)
# -----------------------------------------------------------------------------

module "s3_lambda_output" {
  source = "../../modules/s3"

  bucket_name        = "${local.name_prefix}-lambda-output"
  versioning_enabled = var.s3_lambda_output_versioning_enabled

  lifecycle_rules = var.s3_lambda_output_lifecycle_rules

  # バケットポリシー
  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaExecutionRole"
        Effect = "Allow"
        Principal = {
          AWS = module.lambda_execution_role.role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.name_prefix}-lambda-output",
          "arn:aws:s3:::${local.name_prefix}-lambda-output/*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# SQS Queues
# -----------------------------------------------------------------------------

# Processor1 SQS
module "sqs_processor1" {
  source = "../../modules/sqs"

  queue_name = "${local.name_prefix}-sqs-processor1"

  message_retention_seconds  = var.processor1_sqs_message_retention_seconds
  visibility_timeout_seconds = var.processor1_sqs_visibility_timeout_seconds
  max_receive_count          = var.processor1_sqs_max_receive_count

  # KMS暗号化設定
  kms_master_key_id = aws_kms_key.sqs.id

  # キューポリシー
  queue_policy = templatefile("${path.module}/policies/projectl-sqs-queue-policy-processor1.json", {
    rosa_pod_iam_role_arn     = var.rosa_pod_iam_role_arn
    lambda_execution_role_arn = module.lambda_execution_role.role_arn
    queue_arn                 = "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${local.name_prefix}-sqs-processor1"
  })

  tags = local.common_tags
}

# Processor2 SQS
module "sqs_processor2" {
  source = "../../modules/sqs"

  queue_name = "${local.name_prefix}-sqs-processor2"

  message_retention_seconds  = var.processor2_sqs_message_retention_seconds
  visibility_timeout_seconds = var.processor2_sqs_visibility_timeout_seconds
  max_receive_count          = var.processor2_sqs_max_receive_count

  # KMS暗号化設定
  kms_master_key_id = aws_kms_key.sqs.id

  # キューポリシー
  queue_policy = templatefile("${path.module}/policies/projectl-sqs-queue-policy-processor2.json", {
    rosa_pod_iam_role_arn     = var.rosa_pod_iam_role_arn
    lambda_execution_role_arn = module.lambda_execution_role.role_arn
    queue_arn                 = "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${local.name_prefix}-sqs-processor2"
  })

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# VPC Endpoint - SQS
# -----------------------------------------------------------------------------

module "sqs_vpc_endpoint" {
  source = "../../modules/vpc-endpoint"

  name         = "${local.name_prefix}-sqs-endpoint"
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.region}.sqs"

  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(module.vpc_endpoint_subnets.subnet_ids)
  security_group_ids  = [module.sqs_endpoint_sg.security_group_id]
  private_dns_enabled = true

  # VPC Endpointポリシー
  policy = templatefile("${path.module}/policies/projectl-sqs-vpc-endpoint-policy.json", {
    rosa_pod_iam_role_arn     = var.rosa_pod_iam_role_arn
    lambda_execution_role_arn = module.lambda_execution_role.role_arn
    sqs_resource_arn          = "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${local.name_prefix}-sqs-*"
  })

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Security Group - CloudWatch Logs VPC Endpoint用
# -----------------------------------------------------------------------------

module "cloudwatch_logs_endpoint_sg" {
  source = "../../modules/security-group"

  name        = "${local.name_prefix}-cwlogs-endpoint-sg"
  description = "Security group for CloudWatch Logs VPC Endpoint"
  vpc_id      = var.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "ROSA Worker Node to CloudWatch Logs Endpoint"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = var.worker_node_sg_id
    },
    {
      description              = "Aurora to CloudWatch Logs Endpoint"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = var.aurora_sg_id
    }
  ]

  # Lambda SGからのIngressは後で追加 (循環参照回避)
  additional_ingress_rules = {
    "from-lambda" = {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.lambda_sg.security_group_id
      description              = "Lambda to CloudWatch Logs Endpoint"
    }
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# VPC Endpoint - CloudWatch Logs
# -----------------------------------------------------------------------------

module "cloudwatch_logs_vpc_endpoint" {
  source = "../../modules/vpc-endpoint"

  name         = "${local.name_prefix}-cwlogs-endpoint"
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.region}.logs"

  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(module.vpc_endpoint_subnets.subnet_ids)
  security_group_ids  = [module.cloudwatch_logs_endpoint_sg.security_group_id]
  private_dns_enabled = true

  # VPC Endpointポリシー
  policy = templatefile("${path.module}/policies/projectl-cloudwatch-logs-vpc-endpoint-policy.json", {
    rosa_pod_iam_role_arn     = var.rosa_pod_iam_role_arn
    lambda_execution_role_arn = module.lambda_execution_role.role_arn
    aurora_monitoring_role_arn = var.aurora_monitoring_role_arn
    region                    = var.region
    account_id                = data.aws_caller_identity.current.account_id
    name_prefix               = local.name_prefix
  })

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Lambda Functions
# -----------------------------------------------------------------------------

# Processor1 Lambda
module "lambda_processor1" {
  source = "../../modules/lambda"

  function_name = "${local.name_prefix}-lambda-processor1"
  description   = var.processor1_description

  runtime     = var.processor1_runtime
  handler     = var.processor1_handler
  memory_size = var.processor1_memory_size
  timeout     = var.processor1_timeout
  source_path = "${path.root}/../../${var.processor1_source_dir}"

  vpc_subnet_ids         = values(module.lambda_subnets.subnet_ids)
  vpc_security_group_ids = [module.lambda_sg.security_group_id]
  lambda_role_arn        = module.lambda_execution_role.role_arn

  environment_variables = {
    SECRETS_NAME          = var.processor1_secrets_name
    S3_OUTPUT_BUCKET_NAME = module.s3_lambda_output.bucket_name
  }

  # AWS Parameters and Secrets Lambda Extension
  layers = [
    "arn:aws:lambda:${var.region}:133490724326:layer:AWS-Parameters-and-Secrets-Lambda-Extension:12"
  ]

  # SQS Event Source Mapping
  sqs_event_source = {
    queue_arn           = module.sqs_processor1.queue_arn
    batch_size          = var.processor1_sqs_batch_size
    maximum_concurrency = var.processor1_sqs_maximum_concurrency
  }

  cloudwatch_logs_retention_days = var.processor1_cloudwatch_logs_retention_days

  tags = local.common_tags
}

# Processor2 Lambda
module "lambda_processor2" {
  source = "../../modules/lambda"

  function_name = "${local.name_prefix}-lambda-processor2"
  description   = var.processor2_description

  runtime     = var.processor2_runtime
  handler     = var.processor2_handler
  memory_size = var.processor2_memory_size
  timeout     = var.processor2_timeout
  source_path = "${path.root}/../../${var.processor2_source_dir}"

  vpc_subnet_ids         = values(module.lambda_subnets.subnet_ids)
  vpc_security_group_ids = [module.lambda_sg.security_group_id]
  lambda_role_arn        = module.lambda_execution_role.role_arn

  environment_variables = {
    SECRETS_NAME          = var.processor2_secrets_name
    S3_OUTPUT_BUCKET_NAME = module.s3_lambda_output.bucket_name
  }

  # AWS Parameters and Secrets Lambda Extension
  layers = [
    "arn:aws:lambda:${var.region}:133490724326:layer:AWS-Parameters-and-Secrets-Lambda-Extension:12"
  ]

  # SQS Event Source Mapping
  sqs_event_source = {
    queue_arn           = module.sqs_processor2.queue_arn
    batch_size          = var.processor2_sqs_batch_size
    maximum_concurrency = var.processor2_sqs_maximum_concurrency
  }

  cloudwatch_logs_retention_days = var.processor2_cloudwatch_logs_retention_days

  tags = local.common_tags
}

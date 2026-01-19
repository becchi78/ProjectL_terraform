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

  # SQS Endpoint SGへのEgressは後で追加 (循環参照回避)
  additional_egress_rules = {
    "to-sqs-endpoint" = {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.sqs_endpoint_sg.security_group_id
      description              = "SQS VPC Endpoint access"
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
      description              = "Worker Node access"
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
      description              = "Lambda access"
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
      resources = [for secret in data.aws_secretsmanager_secret.lambda : secret.arn]
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

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sqs-kms-key"
  })
}

resource "aws_kms_alias" "sqs" {
  name          = "alias/${local.name_prefix}-sqs"
  target_key_id = aws_kms_key.sqs.key_id
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
        Sid    = "AllowLambdaExecutionRoleOnly"
        Effect = "Allow"
        Principal = {
          AWS = module.lambda_execution_role.role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${local.name_prefix}-lambda-output/*"
      },
      {
        Sid    = "AllowLambdaListBucket"
        Effect = "Allow"
        Principal = {
          AWS = module.lambda_execution_role.role_arn
        }
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${local.name_prefix}-lambda-output"
      },
      {
        Sid       = "DenyAllOthers"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "arn:aws:s3:::${local.name_prefix}-lambda-output",
          "arn:aws:s3:::${local.name_prefix}-lambda-output/*"
        ]
        Condition = {
          StringNotEquals = {
            "aws:PrincipalArn" = module.lambda_execution_role.role_arn
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# SQS Queues
# Lambda関数ごとにSQS + DLQを作成
# -----------------------------------------------------------------------------

module "sqs" {
  source   = "../../modules/sqs"
  for_each = var.lambda_functions

  queue_name = "${local.name_prefix}-sqs-${each.key}"

  message_retention_seconds  = var.sqs_message_retention_seconds
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  max_receive_count          = var.sqs_max_receive_count

  # KMS暗号化設定
  kms_master_key_id = aws_kms_key.sqs.id

  # キューポリシー
  queue_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowROSAPodAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.rosa_pod_iam_role_arn
        }
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${local.name_prefix}-sqs-${each.key}"
      },
      {
        Sid    = "AllowLambdaAccess"
        Effect = "Allow"
        Principal = {
          AWS = module.lambda_execution_role.role_arn
        }
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${local.name_prefix}-sqs-${each.key}"
      }
    ]
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
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowROSAPodAccess"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${local.name_prefix}-sqs-*"
        Condition = {
          ArnEquals = {
            "aws:PrincipalArn" = var.rosa_pod_iam_role_arn
          }
        }
      },
      {
        Sid       = "AllowLambdaAccess"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${local.name_prefix}-sqs-*"
        Condition = {
          ArnEquals = {
            "aws:PrincipalArn" = module.lambda_execution_role.role_arn
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Lambda Functions
# -----------------------------------------------------------------------------

module "lambda" {
  source   = "../../modules/lambda"
  for_each = var.lambda_functions

  function_name = "${local.name_prefix}-lambda-${each.key}"
  description   = each.value.description

  runtime     = each.value.runtime
  handler     = each.value.handler
  memory_size = each.value.memory_size
  timeout     = each.value.timeout
  source_path = "${path.root}/../../${each.value.source_dir}"

  vpc_subnet_ids         = values(module.lambda_subnets.subnet_ids)
  vpc_security_group_ids = [module.lambda_sg.security_group_id]
  lambda_role_arn        = module.lambda_execution_role.role_arn

  environment_variables = {
    SECRETS_NAME          = each.value.secrets_name
    S3_OUTPUT_BUCKET_NAME = module.s3_lambda_output.bucket_name
  }

  # AWS Parameters and Secrets Lambda Extension
  layers = [
    "arn:aws:lambda:${var.region}:133490724326:layer:AWS-Parameters-and-Secrets-Lambda-Extension:12"
  ]

  # SQS Event Source Mapping
  sqs_event_source = {
    queue_arn           = module.sqs[each.key].queue_arn
    batch_size          = var.sqs_batch_size
    maximum_concurrency = var.sqs_maximum_concurrency
  }

  cloudwatch_logs_retention_days = var.cloudwatch_logs_retention_days

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# 既存リソースの参照
# -----------------------------------------------------------------------------

# 現在のAWSアカウント情報
data "aws_caller_identity" "current" {}

# VPC
data "aws_vpc" "main" {
  id = var.vpc_id
}

# Worker Node用サブネット
data "aws_subnets" "worker_node" {
  filter {
    name   = "subnet-id"
    values = var.worker_node_subnet_ids
  }
}

# Aurora Cluster
data "aws_rds_cluster" "aurora" {
  cluster_identifier = var.aurora_cluster_id
}

# Aurora Security Group
data "aws_security_group" "aurora" {
  id = var.aurora_sg_id
}

# Worker Node Security Group
data "aws_security_group" "worker_node" {
  id = var.worker_node_sg_id
}

# Secrets Manager Secret
data "aws_secretsmanager_secret" "aurora" {
  name = var.aurora_secret_name
}

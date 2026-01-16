# -----------------------------------------------------------------------------
# 出力値
# -----------------------------------------------------------------------------

output "subnet_ids" {
  description = "作成したサブネットのIDマップ"
  value       = { for k, v in aws_subnet.this : k => v.id }
}

output "subnet_arns" {
  description = "作成したサブネットのARNマップ"
  value       = { for k, v in aws_subnet.this : k => v.arn }
}

output "subnet_cidrs" {
  description = "作成したサブネットのCIDRマップ"
  value       = { for k, v in aws_subnet.this : k => v.cidr_block }
}

output "availability_zones" {
  description = "使用しているアベイラビリティゾーン"
  value       = local.azs
}

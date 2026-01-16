# -----------------------------------------------------------------------------
# 出力値
# -----------------------------------------------------------------------------

output "security_group_id" {
  description = "Security GroupのID"
  value       = module.this.security_group_id
}

output "security_group_arn" {
  description = "Security GroupのARN"
  value       = module.this.security_group_arn
}

output "security_group_name" {
  description = "Security Groupの名前"
  value       = module.this.security_group_name
}

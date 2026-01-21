# -----------------------------------------------------------------------------
# 出力値
# -----------------------------------------------------------------------------

output "role_arn" {
  description = "IAMロールのARN"
  value       = module.this.arn
}

output "role_name" {
  description = "IAMロールの名前"
  value       = module.this.name
}

output "role_id" {
  description = "IAMロールのID"
  value       = module.this.unique_id
}

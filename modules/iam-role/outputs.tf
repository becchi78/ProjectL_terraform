# -----------------------------------------------------------------------------
# 出力値
# -----------------------------------------------------------------------------

output "role_arn" {
  description = "IAMロールのARN"
  value       = module.this.iam_role_arn
}

output "role_name" {
  description = "IAMロールの名前"
  value       = module.this.iam_role_name
}

output "role_id" {
  description = "IAMロールのID"
  value       = module.this.iam_role_unique_id
}

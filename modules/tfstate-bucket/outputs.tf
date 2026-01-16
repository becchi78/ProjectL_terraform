# -----------------------------------------------------------------------------
# 出力値
# -----------------------------------------------------------------------------

output "bucket_id" {
  description = "S3バケットのID"
  value       = module.s3_bucket.s3_bucket_id
}

output "bucket_arn" {
  description = "S3バケットのARN"
  value       = module.s3_bucket.s3_bucket_arn
}

output "bucket_region" {
  description = "S3バケットのリージョン"
  value       = module.s3_bucket.s3_bucket_region
}

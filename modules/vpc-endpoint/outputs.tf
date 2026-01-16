# -----------------------------------------------------------------------------
# 出力値
# -----------------------------------------------------------------------------

output "id" {
  description = "VPC EndpointのID"
  value       = aws_vpc_endpoint.this.id
}

output "arn" {
  description = "VPC EndpointのARN"
  value       = aws_vpc_endpoint.this.arn
}

output "dns_entry" {
  description = "VPC EndpointのDNSエントリ (Interface Endpointのみ)"
  value       = aws_vpc_endpoint.this.dns_entry
}

output "network_interface_ids" {
  description = "VPC EndpointのネットワークインターフェースID (Interface Endpointのみ)"
  value       = aws_vpc_endpoint.this.network_interface_ids
}

output "state" {
  description = "VPC Endpointの状態"
  value       = aws_vpc_endpoint.this.state
}

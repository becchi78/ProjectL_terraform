# -----------------------------------------------------------------------------
# 汎用サブネット作成モジュール
# -----------------------------------------------------------------------------

# アベイラビリティゾーンの取得
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

# -----------------------------------------------------------------------------
# サブネット
# -----------------------------------------------------------------------------

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = local.azs[each.value.az_index % length(local.azs)]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${each.key}-${local.azs[each.value.az_index % length(local.azs)]}"
  }, lookup(each.value, "tags", {}))
}

# サブネットのルートテーブル関連付け
resource "aws_route_table_association" "this" {
  for_each = { for k, v in var.subnets : k => v if var.route_table_id != "" }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = var.route_table_id
}

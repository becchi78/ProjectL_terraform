# -----------------------------------------------------------------------------
# 汎用Security Groupモジュール
# -----------------------------------------------------------------------------

module "this" {
  source = "../../../terraform-local/modules/security_group"

  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id

  # Ingressルール
  ingress_with_source_security_group_id = var.ingress_with_source_security_group_id
  ingress_with_cidr_blocks              = var.ingress_with_cidr_blocks
  ingress_with_self                     = var.ingress_with_self

  # Egressルール
  egress_with_source_security_group_id = var.egress_with_source_security_group_id
  egress_with_cidr_blocks              = var.egress_with_cidr_blocks

  tags = var.tags
}

# 追加のSecurity Groupルール (循環参照回避など)
resource "aws_security_group_rule" "additional_ingress" {
  for_each = var.additional_ingress_rules

  type                     = "ingress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  security_group_id        = module.this.security_group_id
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  description              = lookup(each.value, "description", null)
}

resource "aws_security_group_rule" "additional_egress" {
  for_each = var.additional_egress_rules

  type                     = "egress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  security_group_id        = module.this.security_group_id
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  description              = lookup(each.value, "description", null)
}

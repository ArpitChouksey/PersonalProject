resource "aws_wafv2_web_acl_association" "this" {
  for_each = var.scope == "REGIONAL" ? toset(var.resource_arns) : toset([])

  resource_arn = each.value
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}

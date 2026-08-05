# ManagedInstanceInventory compliance data isn't a resource you create - it's
# generated once an association runs the AWS-managed AWS-GatherSoftwareInventory
# document against your instances. This just wires that association up.

resource "aws_ssm_association" "inventory" {
  count = var.enable_inventory ? 1 : 0

  association_name    = "${var.name_prefix}-inventory"
  name                = "AWS-GatherSoftwareInventory"
  schedule_expression = var.inventory_schedule_expression

  dynamic "targets" {
    for_each = var.inventory_targets
    content {
      key    = targets.value.key
      values = targets.value.values
    }
  }

  dynamic "output_location" {
    for_each = var.create_reports_bucket ? [1] : []
    content {
      s3_bucket_name = local.reports_bucket_name
      s3_key_prefix  = "inventory/"
    }
  }
}

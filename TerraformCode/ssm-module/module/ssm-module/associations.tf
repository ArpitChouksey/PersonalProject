resource "aws_ssm_association" "this" {
  for_each = var.enable_associations ? var.associations : {}

  association_name = each.value.name
  name             = each.value.document_name
  document_version = each.value.document_version

  schedule_expression  = each.value.schedule_expression
  compliance_severity  = each.value.compliance_severity
  max_errors           = each.value.max_errors
  max_concurrency      = each.value.max_concurrency
  parameters           = each.value.parameters

  dynamic "targets" {
    for_each = each.value.targets
    content {
      key    = targets.value.key
      values = targets.value.values
    }
  }

  dynamic "output_location" {
    for_each = each.value.write_output_to_s3 && var.create_reports_bucket ? [1] : []
    content {
      s3_bucket_name = local.reports_bucket_name
      s3_key_prefix  = "associations/${each.value.name}/"
    }
  }

  # If document_name points at a custom document created above, make sure it
  # exists first. Harmless no-op when document_name is an AWS-managed doc.
  depends_on = [aws_ssm_document.this]
}

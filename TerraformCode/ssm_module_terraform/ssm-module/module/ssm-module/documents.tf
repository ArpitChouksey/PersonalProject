resource "aws_ssm_document" "this" {
  for_each = var.enable_documents ? var.documents : {}

  name            = each.value.name
  document_type   = each.value.document_type
  document_format = each.value.document_format
  content         = each.value.content

  tags = var.tags
}

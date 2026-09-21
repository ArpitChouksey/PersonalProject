resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type

    kms_key = var.encryption_type == "KMS" ? var.kms_key_arn : null
  }

  force_delete = var.force_delete

  tags = merge(
    var.tags,
    {
      Name = var.repository_name
    }
  )
}

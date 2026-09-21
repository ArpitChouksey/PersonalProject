resource "aws_secretsmanager_secret" "this" {
  name        = var.secret_name
  description = var.description

  kms_key_id = var.kms_key_id

  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(
    var.tags,
    {
      Name = var.secret_name
    }
  )
}

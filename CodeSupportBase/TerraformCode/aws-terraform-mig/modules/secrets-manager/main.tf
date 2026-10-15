# ============================================================
# SECRETS MANAGER SECRET
# ============================================================

resource "aws_secretsmanager_secret" "this" {
  name        = var.secret_name
  description = var.description

  recovery_window_in_days = 30

  force_overwrite_replica_secret = false

  tags = var.tags
}

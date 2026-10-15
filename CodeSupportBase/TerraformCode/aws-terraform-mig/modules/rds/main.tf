# ============================================================
# RDS SUBNET GROUP
# ============================================================

resource "aws_db_subnet_group" "this" {
  name        = var.subnet_group_name
  description = var.subnet_group_description
  subnet_ids  = var.subnet_ids

  tags = var.tags
}


# ============================================================
# RDS DATABASE INSTANCE
# ============================================================

resource "aws_db_instance" "this" {
  identifier = var.identifier

  # ----------------------------------------------------------
  # Engine
  # ----------------------------------------------------------

  engine         = "postgres"
  engine_version = var.engine_version


  # ----------------------------------------------------------
  # Compute
  # ----------------------------------------------------------

  instance_class = var.instance_class


  # ----------------------------------------------------------
  # Storage
  # ----------------------------------------------------------

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  storage_type      = var.storage_type
  storage_encrypted = var.storage_encrypted


  # ----------------------------------------------------------
  # Database
  # ----------------------------------------------------------

  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = var.port


  # ----------------------------------------------------------
  # Networking
  # ----------------------------------------------------------

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids


  # ----------------------------------------------------------
  # Availability
  # ----------------------------------------------------------

  multi_az            = var.multi_az
  publicly_accessible = var.publicly_accessible


  # ----------------------------------------------------------
  # Backup / Deletion
  # ----------------------------------------------------------

  skip_final_snapshot      = var.skip_final_snapshot
  deletion_protection      = var.deletion_protection
  backup_retention_period  = var.backup_retention_period


  # ----------------------------------------------------------
  # Performance
  # ----------------------------------------------------------

  performance_insights_enabled = var.performance_insights_enabled


  # ----------------------------------------------------------
  # Snapshot
  # ----------------------------------------------------------

  copy_tags_to_snapshot = var.copy_tags_to_snapshot


  # ----------------------------------------------------------
  # Apply behavior
  # ----------------------------------------------------------

  apply_immediately = false


  # ----------------------------------------------------------
  # Tags
  # ----------------------------------------------------------

  tags = var.tags
}

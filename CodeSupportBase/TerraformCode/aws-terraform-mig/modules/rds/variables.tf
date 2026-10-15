# ============================================================
# RDS INSTANCE
# ============================================================

variable "identifier" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  type = number
}

variable "max_allocated_storage" {
  type    = number
  default = null
}

variable "storage_type" {
  type    = string
  default = "gp3"
}

variable "storage_encrypted" {
  type    = bool
  default = true
}

variable "db_name" {
  type    = string
  default = null
}

variable "username" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
  default   = null
}

variable "port" {
  type    = number
  default = 5432
}


# ============================================================
# SUBNET GROUP
# ============================================================

variable "subnet_group_name" {
  type = string
}

variable "subnet_group_description" {
  type    = string
  default = null
}

variable "subnet_ids" {
  type = list(string)
}


# ============================================================
# NETWORKING
# ============================================================

variable "security_group_ids" {
  type = list(string)
}


# ============================================================
# AVAILABILITY
# ============================================================

variable "multi_az" {
  type    = bool
  default = false
}

variable "publicly_accessible" {
  type    = bool
  default = false
}


# ============================================================
# BACKUP / DELETION
# ============================================================

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "backup_retention_period" {
  type    = number
  default = 1
}


# ============================================================
# PERFORMANCE
# ============================================================

variable "performance_insights_enabled" {
  type    = bool
  default = false
}

variable "copy_tags_to_snapshot" {
  type    = bool
  default = false
}


# ============================================================
# TAGS
# ============================================================

variable "tags" {
  type    = map(string)
  default = {}
}

# ============================================================
# AWS
# ============================================================

variable "aws_region" {
  type = string
}


# ============================================================
# VPC
# ============================================================

variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "vpc_tags" {
  type    = map(string)
  default = {}
}

variable "enable_dns_support" {
  type = bool
}

variable "enable_dns_hostnames" {
  type = bool
}


# ============================================================
# SUBNETS
# ============================================================

variable "subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
    name              = string
  }))
}


# ============================================================
# INTERNET GATEWAY
# ============================================================

variable "internet_gateway_name" {
  type = string
}


# ============================================================
# ROUTE TABLES
# ============================================================

variable "route_tables" {
  type = map(object({
    name = string

    routes = map(object({
      destination_cidr_block = string
      gateway_id             = optional(string)
    }))

    subnet_names = list(string)
  }))
}


# ============================================================
# SECURITY GROUPS
# ============================================================

variable "security_groups" {
  type = map(object({
    name        = string
    description = string

    ingress = list(object({
      description     = string
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = list(string)
      security_groups = list(string)
    }))

    egress = list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
  }))
}


# ============================================================
# S3
# ============================================================

variable "s3_bucket_name" {
  type = string
}

variable "s3_versioning_enabled" {
  type    = bool
  default = true
}

variable "s3_sse_algorithm" {
  type    = string
  default = "AES256"
}


# ============================================================
# SECRETS MANAGER
# ============================================================

variable "secret_name" {
  type = string
}

variable "secret_description" {
  type    = string
  default = null
}


# ============================================================
# IAM
# ============================================================

variable "iam_role_name" {
  type = string
}

variable "iam_role_description" {
  type    = string
  default = null
}

variable "iam_instance_profile_name" {
  type = string
}

variable "iam_s3_policy_name" {
  type = string
}

variable "iam_secrets_manager_policy_name" {
  type = string
}

variable "iam_secrets_manager_policy_resource" {
  type = string
}


# ============================================================
# EC2
# ============================================================

variable "ec2_name" {
  type = string
}

variable "ec2_ami_id" {
  type = string
}

variable "ec2_instance_type" {
  type = string
}

variable "ec2_subnet_id" {
  type = string
}

variable "ec2_security_group_ids" {
  type = list(string)
}

variable "ec2_iam_instance_profile" {
  type = string
}

variable "ec2_associate_public_ip" {
  type    = bool
  default = false
}

variable "ec2_disable_api_stop" {
  type    = bool
  default = false
}

variable "ec2_disable_api_termination" {
  type    = bool
  default = false
}


# ============================================================
# RDS
# ============================================================

variable "rds_identifier" {
  type = string
}

variable "rds_engine_version" {
  type = string
}

variable "rds_instance_class" {
  type = string
}

variable "rds_allocated_storage" {
  type = number
}

variable "rds_max_allocated_storage" {
  type    = number
  default = null
}

variable "rds_storage_type" {
  type    = string
  default = "gp3"
}

variable "rds_storage_encrypted" {
  type    = bool
  default = true
}

variable "rds_db_name" {
  type    = string
  default = null
}

variable "rds_master_username" {
  type = string
}

variable "rds_master_password" {
  type      = string
  sensitive = true
  default   = null
}

variable "rds_port" {
  type    = number
  default = 5432
}

variable "rds_subnet_group_name" {
  type = string
}

variable "rds_subnet_group_description" {
  type    = string
  default = null
}

variable "rds_subnet_ids" {
  type = list(string)
}

variable "rds_security_group_ids" {
  type = list(string)
}

variable "rds_multi_az" {
  type    = bool
  default = false
}

variable "rds_publicly_accessible" {
  type    = bool
  default = false
}

variable "rds_skip_final_snapshot" {
  type    = bool
  default = true
}

variable "rds_deletion_protection" {
  type    = bool
  default = false
}

variable "rds_backup_retention_period" {
  type    = number
  default = 1
}

variable "rds_performance_insights_enabled" {
  type    = bool
  default = false
}

variable "rds_copy_tags_to_snapshot" {
  type    = bool
  default = false
}

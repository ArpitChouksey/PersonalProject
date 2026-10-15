# ============================================================
# VPC
# ============================================================

module "vpc" {
  source = "../../modules/vpc"

  name                 = var.vpc_name
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  tags                 = var.vpc_tags
}


# ============================================================
# SUBNETS
# ============================================================

module "subnet" {
  source = "../../modules/subnet"

  vpc_id  = module.vpc.vpc_id
  subnets = var.subnets
}


# ============================================================
# INTERNET GATEWAY
# ============================================================

module "internet_gateway" {
  source = "../../modules/internet-gateway"

  vpc_id = module.vpc.vpc_id
  name   = var.internet_gateway_name
}


# ============================================================
# ROUTE TABLES
# ============================================================

module "route_table" {
  source = "../../modules/route-table"

  vpc_id              = module.vpc.vpc_id
  internet_gateway_id = module.internet_gateway.internet_gateway_id
  subnet_ids          = module.subnet.subnet_ids
  route_tables        = var.route_tables
}


# ============================================================
# SECURITY GROUPS
# ============================================================

module "security_group" {
  source = "../../modules/security-group"

  vpc_id          = module.vpc.vpc_id
  security_groups = var.security_groups
}


# ============================================================
# S3
# ============================================================

module "s3" {
  source = "../../modules/s3"

  bucket_name        = var.s3_bucket_name
  versioning_enabled = var.s3_versioning_enabled
  sse_algorithm      = var.s3_sse_algorithm
}


# ============================================================
# SECRETS MANAGER
# ============================================================

module "secrets_manager" {
  source = "../../modules/secrets-manager"

  secret_name = var.secret_name
  description = var.secret_description
}


# ============================================================
# IAM ROLE
# ============================================================

module "iam_role" {
  source = "../../modules/iam-role"

  role_name = var.iam_role_name

  role_description = var.iam_role_description

  instance_profile_name = var.iam_instance_profile_name

  s3_policy_name = var.iam_s3_policy_name

  secrets_manager_policy_name = var.iam_secrets_manager_policy_name

  s3_bucket_arn = module.s3.bucket_arn

  secret_policy_resource = var.iam_secrets_manager_policy_resource
}


# ============================================================
# EC2
# ============================================================

module "ec2" {
  source = "../../modules/ec2"

  name = var.ec2_name

  ami_id = var.ec2_ami_id

  instance_type = var.ec2_instance_type

  subnet_id = var.ec2_subnet_id

  security_group_ids = var.ec2_security_group_ids

  iam_instance_profile = var.ec2_iam_instance_profile

  associate_public_ip_address = var.ec2_associate_public_ip

  disable_api_stop = var.ec2_disable_api_stop

  disable_api_termination = var.ec2_disable_api_termination
}


# ============================================================
# RDS
# ============================================================

module "rds" {
  source = "../../modules/rds"

  identifier = var.rds_identifier

  engine_version = var.rds_engine_version

  instance_class = var.rds_instance_class

  allocated_storage = var.rds_allocated_storage

  max_allocated_storage = var.rds_max_allocated_storage

  storage_type = var.rds_storage_type

  storage_encrypted = var.rds_storage_encrypted

  db_name = var.rds_db_name

  username = var.rds_master_username

  password = var.rds_master_password

  port = var.rds_port

  subnet_group_name = var.rds_subnet_group_name

  subnet_group_description = var.rds_subnet_group_description

  subnet_ids = var.rds_subnet_ids

  security_group_ids = var.rds_security_group_ids

  multi_az = var.rds_multi_az

  publicly_accessible = var.rds_publicly_accessible

  skip_final_snapshot = var.rds_skip_final_snapshot

  deletion_protection = var.rds_deletion_protection

  backup_retention_period = var.rds_backup_retention_period

  performance_insights_enabled = var.rds_performance_insights_enabled

  copy_tags_to_snapshot = var.rds_copy_tags_to_snapshot
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "subnet_ids" {
  value = module.subnet.subnet_ids
}

output "internet_gateway_id" {
  value = module.internet_gateway.internet_gateway_id
}

output "route_table_ids" {
  value = module.route_table.route_table_ids
}

output "security_group_ids" {
  value = module.security_group.security_group_ids
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "s3_bucket_arn" {
  value = module.s3.bucket_arn
}

output "secret_name" {
  value = module.secrets_manager.secret_name
}

output "secret_arn" {
  value = module.secrets_manager.secret_arn
}

output "iam_role_name" {
  value = module.iam_role.role_name
}

output "iam_role_arn" {
  value = module.iam_role.role_arn
}

output "ec2_instance_id" {
  value = module.ec2.instance_id
}

output "ec2_private_ip" {
  value = module.ec2.private_ip
}

output "ec2_public_ip" {
  value = module.ec2.public_ip
}

output "rds_instance_id" {
  value = module.rds.db_instance_id
}

output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "rds_port" {
  value = module.rds.db_port
}

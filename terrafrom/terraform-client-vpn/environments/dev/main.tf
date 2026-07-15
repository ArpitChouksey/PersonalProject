module "networking" {

  source = "../../modules/networking"

  project_name = var.project_name

  environment = var.environment

  vpc_cidr = var.vpc_cidr

  enable_dns_support = var.enable_dns_support

  enable_dns_hostnames = var.enable_dns_hostnames

  app_subnet_cidr = var.app_subnet_cidr

  db_subnet_cidr = var.db_subnet_cidr

  app_subnet_az = var.app_subnet_az

  db_subnet_az = var.db_subnet_az

  tags = var.tags

}

module "iam" {

  source = "../../modules/iam"

  project_name = var.project_name

  environment = var.environment

  role_name = "clientvpn-role"

  instance_profile_name = "clientvpn-profile"

  tags = var.tags

}

module "security_groups" {

  source = "../../modules/security-groups"

  project_name = var.project_name

  environment = var.environment

  vpn_cidr = var.vpn_cidr

  vpc_id = module.networking.vpc_id

  database_port = 5432

  tags = var.tags

}

module "windows" {

  source = "../../modules/ec2"

  project_name = var.project_name
  environment  = var.environment

  instance_name = var.windows_instance_name

  ami_id        = var.windows_ami
  instance_type = var.windows_instance_type

  subnet_id = module.networking.app_subnet_id

  private_ip = var.windows_private_ip

  key_name = var.key_name

  iam_instance_profile = module.iam.instance_profile_name

  security_group_ids = [
    module.security_groups.windows_security_group_id
  ]

  associate_public_ip_address = false

  root_volume_size = var.windows_root_volume_size
  root_volume_type = var.root_volume_type

  encrypted = true

  delete_on_termination = true

  monitoring = true

  disable_api_termination = false

  ebs_optimized = false

  user_data = null

  tags = var.tags
}

module "linux" {

  source = "../../modules/ec2"

  project_name = var.project_name
  environment  = var.environment

  instance_name = var.linux_instance_name

  ami_id        = var.linux_ami
  instance_type = var.linux_instance_type

  subnet_id = module.networking.app_subnet_id

  private_ip = var.linux_private_ip

  key_name = var.key_name

  iam_instance_profile = module.iam.instance_profile_name

  security_group_ids = [
    module.security_groups.linux_security_group_id
  ]

  associate_public_ip_address = false

  root_volume_size = var.linux_root_volume_size
  root_volume_type = var.root_volume_type

  encrypted = true

  delete_on_termination = true

  monitoring = true

  disable_api_termination = false

  ebs_optimized = false

  user_data = null

  tags = var.tags
}


module "vpn" {

  source = "../../modules/vpn"

  project_name = var.project_name

  environment = var.environment

  vpn_name = var.vpn_name

  client_cidr_block = var.client_cidr_block

  server_certificate_arn = var.server_certificate_arn

  root_certificate_chain_arn = var.root_certificate_chain_arn

  transport_protocol = var.transport_protocol

  vpn_port = var.vpn_port

  split_tunnel = var.split_tunnel

  session_timeout_hours = var.session_timeout_hours

  dns_servers = var.dns_servers

  vpc_id = module.networking.vpc_id

  target_subnet_id = module.networking.app_subnet_id

  destination_cidr_block = var.vpc_cidr

  authorize_all_groups = true

  tags = var.tags

}

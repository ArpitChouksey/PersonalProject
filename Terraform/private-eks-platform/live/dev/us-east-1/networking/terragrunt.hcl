include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  region_config = read_terragrunt_config(
    find_in_parent_folders("region.hcl")
  )

  environment_config = read_terragrunt_config(
    find_in_parent_folders("env.hcl")
  )
}

terraform {
  source = "../../../../modules/networking"
}

inputs = {
  aws_region = local.region_config.locals.aws_region

  project_name = local.environment_config.locals.project_name
  environment = local.environment_config.locals.environment

  vpc_cidr = local.environment_config.locals.vpc_cidr

  availability_zones = local.environment_config.locals.availability_zones

  public_subnets = local.environment_config.locals.public_subnets

  private_subnets = local.environment_config.locals.private_subnets

  enable_dns_support = local.environment_config.locals.enable_dns_support

  enable_dns_hostnames = local.environment_config.locals.enable_dns_hostnames

  enable_flow_logs = local.environment_config.locals.enable_flow_logs

  tags = local.environment_config.locals.common_tags
}

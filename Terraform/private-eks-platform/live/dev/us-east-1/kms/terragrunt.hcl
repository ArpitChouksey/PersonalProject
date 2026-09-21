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

  aws_region   = local.region_config.locals.aws_region
  environment  = local.environment_config.locals.environment
  project_name = local.environment_config.locals.project_name
  common_tags  = local.environment_config.locals.common_tags
}

terraform {
  source = "../../../../modules/kms"
}

inputs = {
  alias_name = "alias/alias/private-eks-platform-secrets"

  description = "KMS key for encrypting secrets used by the private EKS platform"

  deletion_window_in_days = 30

  enable_key_rotation = false

  multi_region = false

  tags = local.common_tags
}

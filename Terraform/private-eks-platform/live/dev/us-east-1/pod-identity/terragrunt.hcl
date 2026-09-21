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
  source = "../../../../modules/pod-identity"
}

inputs = {
  cluster_name = "private-eks-platform"

  namespace = "secret-test"

  service_account = "secret-reader"

  role_arn = "arn:aws:iam::211811255273:role/eks-secret-reader-role"

  tags = local.common_tags
}

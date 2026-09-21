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
  source = "../../../../modules/iam"
}

inputs = {
  secret_reader_role_name = "eks-secret-reader-role"

  secret_reader_role_description = "Allows pods running in Amazon EKS cluster to access AWS resources."

  secret_reader_policy_name = "eks-secret-reader-policy"

  secret_arn = "arn:aws:secretsmanager:us-east-1:211811255273:secret:private-eks-platform/app/test-VH26bP"

  kms_key_arn = "arn:aws:kms:us-east-1:211811255273:key/d118c33a-ae0f-4ef6-8f48-09373cbad92e"

  tags = local.common_tags
}

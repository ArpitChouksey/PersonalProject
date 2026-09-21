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

dependency "networking" {
  config_path = "../networking"

  mock_outputs = {
    vpc_id = "vpc-00000000000000000"

    private_subnet_ids = [
      "subnet-00000000000000000",
      "subnet-00000000000000001"
    ]
  }

  mock_outputs_allowed_terraform_commands = [
    "validate",
    "plan"
  ]
}

terraform {
  source = "../../../../modules/eks"
}

inputs = {
  # ==========================================================
  # EKS CLUSTER
  # ==========================================================

  cluster_name       = "private-eks-platform"
  cluster_role_arn   = "arn:aws:iam::211811255273:role/eks-private-cluster-role"
  kubernetes_version = "1.36"

  bootstrap_cluster_creator_admin_permissions = true

  authentication_mode = "API"

  # Existing cluster uses private subnets
  subnet_ids = dependency.networking.outputs.private_subnet_ids

  # Existing managed node group also uses private subnets
  node_subnet_ids = dependency.networking.outputs.private_subnet_ids

  # Existing cluster does not have additional SGs configured
  # EKS automatically created/uses its cluster security group.
  security_group_ids = []


  # ==========================================================
  # MANAGED NODE GROUP
  # ==========================================================

  node_group_name = "private-ng-03"

  node_role_arn = "arn:aws:iam::211811255273:role/eks-private-node-role"

  node_ami_type = "AL2023_x86_64_STANDARD"

  node_capacity_type = "ON_DEMAND"

  node_instance_types = [
    "t3.medium"
  ]

  node_disk_size = 20

  node_desired_size = 2

  node_min_size = 2

  node_max_size = 2

  node_max_unavailable = 1


  # ==========================================================
  # EKS ADD-ONS
  # ==========================================================

  enable_vpc_cni_addon = true

  enable_coredns_addon = true

  enable_kube_proxy_addon = true

  enable_pod_identity_addon = true

  enable_metrics_server_addon = true


  # ==========================================================
  # TAGS
  # ==========================================================

  tags = local.common_tags
}

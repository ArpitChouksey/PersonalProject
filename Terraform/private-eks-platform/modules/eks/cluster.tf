resource "aws_eks_cluster" "this" {

  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  access_config {
    authentication_mode = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = var.security_group_ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  zonal_shift_config {
    enabled = false
  }

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )
}

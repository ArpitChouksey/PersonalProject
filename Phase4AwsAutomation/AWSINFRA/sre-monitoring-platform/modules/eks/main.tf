resource "aws_eks_cluster" "main" {

  name     = var.cluster_name
  role_arn = var.cluster_role_arn

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  vpc_config {

    subnet_ids = var.subnet_ids

    endpoint_public_access  = true
    endpoint_private_access = true
  }

lifecycle {
  ignore_changes = [
    zonal_shift_config
  ]
}

}

resource "aws_eks_node_group" "main" {

  cluster_name    = aws_eks_cluster.main.name

  node_group_name = var.node_group_name

  node_role_arn = var.node_role_arn

  subnet_ids = [
    var.private_subnet_a,
    var.private_subnet_b
  ]

  scaling_config {

    desired_size = var.desired_size

    min_size = var.min_size

    max_size = var.max_size
  }

  instance_types = var.instance_types

  depends_on = [
    aws_eks_cluster.main
  ]
}

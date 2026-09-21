# ============================================================
# EKS MANAGED NODE GROUP
# ============================================================

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn

  subnet_ids = var.node_subnet_ids

  version = var.kubernetes_version

  ami_type       = var.node_ami_type
  capacity_type  = var.node_capacity_type
  instance_types = var.node_instance_types
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = var.node_max_unavailable
    update_strategy  = "DEFAULT"
  }

  labels = var.node_labels

  tags = merge(
    var.tags,
    {
      Name = var.node_group_name
    }
  )

  depends_on = [
    aws_eks_cluster.this
  ]
}

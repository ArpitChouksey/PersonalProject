# ============================================================
# EKS ADD-ONS
# ============================================================

resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_vpc_cni_addon ? 1 : 0

  cluster_name = aws_eks_cluster.this.name

  addon_name    = "vpc-cni"
  addon_version = var.vpc_cni_addon_version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [
    aws_eks_cluster.this
  ]
}


resource "aws_eks_addon" "coredns" {
  count = var.enable_coredns_addon ? 1 : 0

  cluster_name = aws_eks_cluster.this.name

  addon_name    = "coredns"
  addon_version = var.coredns_addon_version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [
    aws_eks_cluster.this
  ]
}


resource "aws_eks_addon" "kube_proxy" {
  count = var.enable_kube_proxy_addon ? 1 : 0

  cluster_name = aws_eks_cluster.this.name

  addon_name    = "kube-proxy"
  addon_version = var.kube_proxy_addon_version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [
    aws_eks_cluster.this
  ]
}


resource "aws_eks_addon" "pod_identity_agent" {
  count = var.enable_pod_identity_addon ? 1 : 0

  cluster_name = aws_eks_cluster.this.name

  addon_name    = "eks-pod-identity-agent"
  addon_version = var.pod_identity_addon_version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [
    aws_eks_cluster.this
  ]
}


resource "aws_eks_addon" "metrics_server" {
  count = var.enable_metrics_server_addon ? 1 : 0

  cluster_name = aws_eks_cluster.this.name

  addon_name    = "metrics-server"
  addon_version = var.metrics_server_addon_version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [
    aws_eks_cluster.this
  ]
}

# ============================================================
# EKS CLUSTER OUTPUTS
# ============================================================

output "cluster_id" {
  description = "EKS cluster ID."
  value       = aws_eks_cluster.this.id
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Private Kubernetes API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "EKS Kubernetes version."
  value       = aws_eks_cluster.this.version
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded Kubernetes cluster CA data."
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}


# ============================================================
# NODE GROUP OUTPUTS
# ============================================================

output "node_group_name" {
  description = "EKS managed node group name."
  value       = aws_eks_node_group.this.node_group_name
}

output "node_group_arn" {
  description = "EKS managed node group ARN."
  value       = aws_eks_node_group.this.arn
}

output "node_role_arn" {
  description = "IAM role ARN used by worker nodes."
  value       = aws_eks_node_group.this.node_role_arn
}


# ============================================================
# ADD-ON OUTPUTS
# ============================================================

output "vpc_cni_addon_version" {
  description = "Installed VPC CNI add-on version."
  value = try(
    aws_eks_addon.vpc_cni[0].addon_version,
    null
  )
}

output "coredns_addon_version" {
  description = "Installed CoreDNS add-on version."
  value = try(
    aws_eks_addon.coredns[0].addon_version,
    null
  )
}

output "kube_proxy_addon_version" {
  description = "Installed kube-proxy add-on version."
  value = try(
    aws_eks_addon.kube_proxy[0].addon_version,
    null
  )
}

output "pod_identity_addon_version" {
  description = "Installed EKS Pod Identity Agent version."
  value = try(
    aws_eks_addon.pod_identity_agent[0].addon_version,
    null
  )
}

output "metrics_server_addon_version" {
  description = "Installed Metrics Server add-on version."
  value = try(
    aws_eks_addon.metrics_server[0].addon_version,
    null
  )
}

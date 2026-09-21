output "association_id" {
  description = "EKS Pod Identity association ID."
  value       = aws_eks_pod_identity_association.this.association_id
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_pod_identity_association.this.cluster_name
}

output "namespace" {
  description = "Kubernetes namespace."
  value       = aws_eks_pod_identity_association.this.namespace
}

output "service_account" {
  description = "Kubernetes service account."
  value       = aws_eks_pod_identity_association.this.service_account
}

output "role_arn" {
  description = "IAM role ARN."
  value       = aws_eks_pod_identity_association.this.role_arn
}

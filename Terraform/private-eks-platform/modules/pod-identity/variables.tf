variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the service account."
  type        = string
}

variable "service_account" {
  description = "Kubernetes service account name."
  type        = string
}

variable "role_arn" {
  description = "IAM role ARN associated with the service account."
  type        = string
}

variable "tags" {
  description = "Tags applied to the Pod Identity association."
  type        = map(string)
  default     = {}
}

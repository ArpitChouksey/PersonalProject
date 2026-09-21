# ============================================================
# GENERAL
# ============================================================

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "cluster_role_arn" {
  description = "IAM role ARN used by the EKS control plane."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster and managed node group."
  type        = string
}

variable "authentication_mode" {
  description = "EKS authentication mode."
  type        = string

  default = "API"

  validation {
    condition = contains(
      ["CONFIG_MAP", "API_AND_CONFIG_MAP", "API"],
      var.authentication_mode
    )

    error_message = "authentication_mode must be CONFIG_MAP, API_AND_CONFIG_MAP, or API."
  }
}


# ============================================================
# NETWORKING
# ============================================================

variable "subnet_ids" {
  description = "Subnet IDs used by the EKS control plane."
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Private subnet IDs used by the managed node group."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups associated with the EKS cluster."
  type        = list(string)

  default = []
}


# ============================================================
# NODE GROUP
# ============================================================

variable "node_group_name" {
  description = "Name of the EKS managed node group."
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN used by EKS worker nodes."
  type        = string
}

variable "node_ami_type" {
  description = "AMI type used by the managed node group."
  type        = string

  default = "AL2023_x86_64_STANDARD"
}

variable "node_capacity_type" {
  description = "Capacity type for the node group."
  type        = string

  default = "ON_DEMAND"

  validation {
    condition = contains(
      ["ON_DEMAND", "SPOT"],
      var.node_capacity_type
    )

    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_instance_types" {
  description = "EC2 instance types used by the managed node group."
  type        = list(string)

  default = ["t3.medium"]
}

variable "node_disk_size" {
  description = "Root disk size in GiB."
  type        = number

  default = 20
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number

  default = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number

  default = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number

  default = 4
}

variable "node_max_unavailable" {
  description = "Maximum number of unavailable nodes during an update."
  type        = number

  default = 1
}

variable "node_labels" {
  description = "Kubernetes labels applied to worker nodes."
  type        = map(string)

  default = {}
}


# ============================================================
# VPC CNI
# ============================================================

variable "enable_vpc_cni_addon" {
  description = "Whether to manage the VPC CNI EKS add-on."
  type        = bool

  default = true
}

variable "vpc_cni_addon_version" {
  description = "Version of the VPC CNI EKS add-on."
  type        = string

  default = null
}


# ============================================================
# COREDNS
# ============================================================

variable "enable_coredns_addon" {
  description = "Whether to manage the CoreDNS EKS add-on."
  type        = bool

  default = true
}

variable "coredns_addon_version" {
  description = "Version of the CoreDNS EKS add-on."
  type        = string

  default = null
}


# ============================================================
# KUBE-PROXY
# ============================================================

variable "enable_kube_proxy_addon" {
  description = "Whether to manage the kube-proxy EKS add-on."
  type        = bool

  default = true
}

variable "kube_proxy_addon_version" {
  description = "Version of the kube-proxy EKS add-on."
  type        = string

  default = null
}


# ============================================================
# EKS POD IDENTITY AGENT
# ============================================================

variable "enable_pod_identity_addon" {
  description = "Whether to manage the EKS Pod Identity Agent add-on."
  type        = bool

  default = true
}

variable "pod_identity_addon_version" {
  description = "Version of the EKS Pod Identity Agent add-on."
  type        = string

  default = null
}


# ============================================================
# METRICS SERVER
# ============================================================

variable "enable_metrics_server_addon" {
  description = "Whether to manage the Metrics Server EKS add-on."
  type        = bool

  default = true
}

variable "metrics_server_addon_version" {
  description = "Version of the Metrics Server EKS add-on."
  type        = string

  default = null
}


# ============================================================
# TAGS
# ============================================================

variable "tags" {
  description = "Common tags applied to EKS resources."
  type        = map(string)

  default = {}
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Whether the cluster creator receives admin permissions."
  type        = bool
  default     = true
}

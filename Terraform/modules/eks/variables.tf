variable "cluster_name" { type = string }
variable "cluster_role_arn" { type = string }
variable "kubernetes_version" { type = string }
variable "subnet_ids" { type = list(string) }
variable "endpoint_private_access" { type = bool }
variable "endpoint_public_access" { type = bool }
variable "cluster_log_types" { type = list(string) }


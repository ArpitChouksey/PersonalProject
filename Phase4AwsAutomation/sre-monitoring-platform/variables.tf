variable "region" {
  description = "AWS Region"
  type        = string
}

variable "email_address" {
  description = "SNS Alert Email"
  type        = string
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "node_group_name" {
  description = "EKS Node Group Name"
  type        = string
}

variable "instance_types" {
  description = "EKS Node Group Instance Types"
  type        = list(string)
}

variable "instance_name" {
  description = "EC2 Instance Name"
  type        = string
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "cluster_role_name" {
  description = "EKS Cluster IAM Role Name"
  type        = string
}

variable "node_role_name" {
  description = "EKS Node IAM Role Name"
  type        = string
}

variable "sg_name" {
  description = "Security Group Name"
  type        = string
}

variable "sg_description" {
  description = "Security Group Description"
  type        = string
}

variable "allowed_ip" {
  description = "Allowed CIDR for admin access"
  type        = string
}

variable "allowed_ports" {
  description = "Allowed ingress ports"
  type        = list(number)
}

variable "trail_name" {
  description = "CloudTrail Name"
  type        = string
}

variable "cloudtrail_bucket_name" {
  description = "CloudTrail S3 Bucket"
  type        = string
}

variable "topic_name" {
  description = "SNS Topic Name"
  type        = string
}

variable "email" {
  description = "SNS Subscription Email"
  type        = string
}

variable "dynamodb_table_name" {
  type = string
}

variable "dynamodb_billing_mode" {
  type = string
}

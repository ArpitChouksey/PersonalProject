variable "name" {
  description = "EC2 instance name"
  type        = string
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
}

variable "associate_public_ip_address" {
  description = "Associate public IP address"
  type        = bool
  default     = false
}

variable "disable_api_stop" {
  description = "Prevent API stop"
  type        = bool
  default     = false
}

variable "disable_api_termination" {
  description = "Prevent API termination"
  type        = bool
  default     = false
}

variable "user_data" {
  description = "Optional EC2 user data"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region for the Control Tower management plane"
  type        = string
  default     = "us-east-1"
}

variable "landing_zone_version" {
  description = "AWS Control Tower Landing Zone version"
  type        = string
  default     = "4.0"
}

variable "manifest_json" {
  description = "Existing AWS Control Tower Landing Zone manifest"
  type        = string
}

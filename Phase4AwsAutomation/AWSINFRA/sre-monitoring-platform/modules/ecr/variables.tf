variable "repository_name" {
  description = "ECR Repository Name"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}

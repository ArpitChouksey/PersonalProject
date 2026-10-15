variable "secret_name" {
  description = "Secrets Manager secret name"
  type        = string
}

variable "description" {
  description = "Secret description"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}

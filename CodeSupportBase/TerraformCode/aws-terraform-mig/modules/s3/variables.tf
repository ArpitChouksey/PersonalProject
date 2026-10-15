variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "versioning_enabled" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "S3 server-side encryption algorithm"
  type        = string
  default     = "AES256"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}

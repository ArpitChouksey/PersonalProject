variable "region" {
  type    = string
  default = "us-west-2"
}

variable "name_prefix" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "create_reports_bucket" {
  type    = bool
  default = true
}

variable "reports_bucket_name" {
  description = "Must be globally unique - account/region specific, never in the shared YAML"
  type        = string
}

variable "enable_reporting_lambda" {
  description = "true = create the compliance/non-compliance CSV report Lambda. false = create only the core SSM pieces."
  type        = bool
  default     = false
}

variable "patch_operations" {
  description = "Optional per-OS override of Scan vs Install, keyed by the same logical OS name as the *-custom.yaml files (e.g. { linux = \"Scan\", windows = \"Install\" }). Any OS not listed here falls back to its YAML file's patch_operation (default \"Install\")."
  type        = map(string)
  default     = {}
}

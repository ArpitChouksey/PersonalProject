###############################################################
# Global Variables
###############################################################

variable "project_name" {
  description = "Project Name"
  type        = string
  default     = "enterprise-platform"
}

variable "environment" {
  description = "Deployment Environment"
  type        = string
  default     = "management"

  validation {
    condition = contains([
      "management",
      "shared",
      "network",
      "security",
      "prod",
      "nonprod",
      "sandbox"
    ], var.environment)

    error_message = "Invalid environment."
  }
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-1"
}

variable "owner" {
  description = "Resource Owner"
  type        = string
  default     = "Platform-Team"
}

variable "cost_center" {
  description = "Cost Center"
  type        = string
  default     = "Cloud"
}

variable "business_unit" {
  description = "Business Unit"
  type        = string
  default     = "Engineering"
}

variable "terraform_version" {
  description = "Terraform Version"
  type        = string
  default     = "1.13.4"
}

variable "aws_profile" {
  description = "AWS CLI Profile"
  type        = string
  default     = "default"
}

variable "tags" {
  description = "Additional custom tags"
  type        = map(string)
  default     = {}
}

# Absolute path to the directory containing API definition YAML
# files. Must be absolute: fileset() resolves a relative path
# against THIS module's own directory, not the root module's, so
# the caller should build it from path.root in a local, e.g.:
#
#   locals {
#     api_definition_path = format("%s/../../../apigatewayconfig/apis", path.root)
#   }
#
variable "api_definition_path" {
  description = "Absolute path to the directory containing API definition YAML files (one file per API)."
  type        = string
}

# Same absolute-path requirement as api_definition_path above --
# fileset()/file() resolve relative paths against this module's
# own directory, not the root module's.
variable "openapi_definition_path" {
  description = "Absolute path to the directory containing OpenAPI/Swagger definition files, for APIs using `import:` instead of the routes/integrations engine."
  type        = string
  default     = ""
}

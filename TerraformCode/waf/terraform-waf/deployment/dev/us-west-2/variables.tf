variable "aws_region" {
  description = "AWS region for this deployment."
  type        = string
}

variable "default_tags" {
  description = "Provider-level default tags applied to every resource in this deployment."
  type        = map(string)
  default     = {}
}

variable "webacl_config_file" {
  description = "Filename (relative to ../../../config/wafconfig/webacls/) of the shared YAML file describing this environment's WAF security policy."
  type        = string
}

##############################################
# Deployment-specific overrides
#
# These three values are NOT in the shared YAML because they genuinely
# differ per region/scope - everything else (managed rules, rate limits,
# IP sets, regex rules, custom rules, tags) is common policy and lives in
# the one shared YAML file instead.
##############################################

variable "scope" {
  description = "WAFv2 scope for this deployment: REGIONAL or CLOUDFRONT."
  type        = string

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "var.scope must be either REGIONAL or CLOUDFRONT."
  }
}

variable "resource_arns" {
  description = "Resource ARNs to associate with the Web ACL. Only used when scope = REGIONAL; leave empty for CLOUDFRONT (attach web_acl_arn to the distribution instead)."
  type        = list(string)
  default     = []
}

variable "log_destination_configs" {
  description = "Region-specific log destination ARNs (Firehose/CloudWatch Logs/S3) for WAF logging."
  type        = list(string)
  default     = []
}

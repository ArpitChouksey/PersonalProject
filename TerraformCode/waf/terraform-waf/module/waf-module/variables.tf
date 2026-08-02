##############################################
# GENERAL
##############################################

variable "name" {
  description = "Base name used to prefix all WAF resources (Web ACL, IP sets, regex pattern sets)."
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 64
    error_message = "var.name must be between 1 and 64 characters."
  }
}

variable "name_prefix" {
  description = "Optional additional prefix (e.g. env/region code) prepended to var.name. Leave empty string to disable."
  type        = string
  default     = ""
}

variable "description" {
  description = "Description applied to the Web ACL."
  type        = string
  default     = "Managed WAFv2 Web ACL"
}

variable "scope" {
  description = "Scope of the Web ACL. REGIONAL for ALB/API Gateway/AppSync, CLOUDFRONT for CloudFront distributions (must be created in us-east-1 when CLOUDFRONT)."
  type        = string

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "var.scope must be either REGIONAL or CLOUDFRONT."
  }
}

variable "default_action" {
  description = "Default action for requests that don't match any rule. Either 'allow' or 'block'."
  type        = string
  default     = "allow"

  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "var.default_action must be either allow or block."
  }
}

variable "tags" {
  description = "Map of tags to apply to all taggable resources created by this module."
  type        = map(string)
  default     = {}
}

##############################################
# VISIBILITY / METRICS
##############################################

variable "cloudwatch_metrics_enabled" {
  description = "Whether to enable CloudWatch metrics for the Web ACL and each rule."
  type        = bool
  default     = true
}

variable "sampled_requests_enabled" {
  description = "Whether to store a sample of web requests for the Web ACL and each rule."
  type        = bool
  default     = true
}

variable "metric_name" {
  description = "CloudWatch metric name for the overall Web ACL. Defaults to var.name if left empty."
  type        = string
  default     = ""
}

##############################################
# AWS MANAGED RULE GROUPS  (see managed-rules.tf)
##############################################

variable "managed_rule_groups" {
  description = <<-EOT
    List of AWS Managed Rule Groups (or Marketplace rule groups) to attach to the Web ACL.
      name                 - Rule name shown in the Web ACL (unique)
      vendor_name          - e.g. "AWS"
      managed_rule_group   - Managed rule group name, e.g. "AWSManagedRulesCommonRuleSet"
      priority             - Integer priority, unique across all rules in the ACL
      override_action      - "none" or "count" (count disables blocking for staged rollout)
      excluded_rules       - List of individual rule names to exclude from the group
      version              - Optional specific managed rule group version, "" for AWS default
  EOT
  type = list(object({
    name               = string
    vendor_name        = string
    managed_rule_group = string
    priority           = number
    override_action    = string
    excluded_rules     = optional(list(string), [])
    version            = optional(string, "")
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.managed_rule_groups : contains(["none", "count"], r.override_action)])
    error_message = "override_action for each managed_rule_group must be 'none' or 'count'."
  }
}

##############################################
# RATE-BASED RULES  (see rate-limit.tf)
##############################################

variable "rate_based_rules" {
  description = <<-EOT
    List of rate-based rules for L7 DDoS / brute-force protection.
      name                  - Unique rule name
      priority              - Integer priority, unique across all rules in the ACL
      limit                 - Max requests per aggregate_key_type per 5-minute window (min 100)
      aggregate_key_type    - "IP" or "FORWARDED_IP"
      forwarded_ip_header   - Header inspected when aggregate_key_type is FORWARDED_IP
      action                - "block" or "count"
  EOT
  type = list(object({
    name                = string
    priority            = number
    limit               = number
    aggregate_key_type  = string
    forwarded_ip_header = optional(string, "X-Forwarded-For")
    action              = string
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.rate_based_rules : contains(["block", "count"], r.action)])
    error_message = "action for each rate_based_rule must be 'block' or 'count'."
  }
  validation {
    condition     = alltrue([for r in var.rate_based_rules : contains(["IP", "FORWARDED_IP"], r.aggregate_key_type)])
    error_message = "aggregate_key_type for each rate_based_rule must be 'IP' or 'FORWARDED_IP'."
  }
}

##############################################
# IP SETS  (see ip-set.tf)
##############################################

variable "ip_sets" {
  description = <<-EOT
    List of IP sets to create and evaluate as rules in the Web ACL.
      name               - Unique IP set / rule name
      priority           - Integer priority, unique across all rules in the ACL
      ip_address_version - "IPV4" or "IPV6"
      addresses          - List of CIDR blocks
      action             - "allow" or "block"
  EOT
  type = list(object({
    name               = string
    priority           = number
    ip_address_version = string
    addresses          = list(string)
    action             = string
  }))
  default = []

  validation {
    condition     = alltrue([for s in var.ip_sets : contains(["allow", "block"], s.action)])
    error_message = "action for each ip_set must be 'allow' or 'block'."
  }
  validation {
    condition     = alltrue([for s in var.ip_sets : contains(["IPV4", "IPV6"], s.ip_address_version)])
    error_message = "ip_address_version for each ip_set must be 'IPV4' or 'IPV6'."
  }
}

##############################################
# GEO-MATCH RULES
##############################################

variable "geo_match_rules" {
  description = <<-EOT
    List of geo-match rules to allow/block/count traffic by country.
      name          - Unique rule name
      priority      - Integer priority, unique across all rules in the ACL
      country_codes - List of ISO 3166-1 alpha-2 country codes, e.g. ["CN", "RU"]
      action        - "allow", "block", or "count"
  EOT
  type = list(object({
    name          = string
    priority      = number
    country_codes = list(string)
    action        = string
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.geo_match_rules : contains(["allow", "block", "count"], r.action)])
    error_message = "action for each geo_match_rule must be 'allow', 'block' or 'count'."
  }
}

##############################################
# REGEX PATTERN SETS  (see regex-pattern.tf)
##############################################

variable "regex_pattern_rules" {
  description = <<-EOT
    List of regex-pattern-set-backed rules (e.g. block requests whose URI matches a set of regexes).
      name                     - Unique regex pattern set / rule name
      priority                 - Integer priority, unique across all rules in the ACL
      action                   - "allow", "block", or "count"
      regex_strings            - List of regex patterns (RE2 syntax) to match against the field
      field_to_match_type      - "uri_path" | "query_string" | "single_header" | "method" | "body"
      header_name              - Header name, required when field_to_match_type = "single_header"
      text_transformation_type - e.g. "NONE", "LOWERCASE", "URL_DECODE", "HTML_ENTITY_DECODE"
  EOT
  type = list(object({
    name                     = string
    priority                 = number
    action                   = string
    regex_strings            = list(string)
    field_to_match_type      = string
    header_name              = optional(string, "")
    text_transformation_type = optional(string, "NONE")
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.regex_pattern_rules : contains(["allow", "block", "count"], r.action)])
    error_message = "action for each regex_pattern_rule must be 'allow', 'block' or 'count'."
  }
  validation {
    condition = alltrue([
      for r in var.regex_pattern_rules :
      contains(["uri_path", "query_string", "single_header", "method", "body"], r.field_to_match_type)
    ])
    error_message = "field_to_match_type must be one of uri_path, query_string, single_header, method, body."
  }
}

##############################################
# CUSTOM RULES  (see custom-rules.tf)
##############################################

variable "custom_rules" {
  description = <<-EOT
    List of custom, single-statement rules for fine-grained matching that the higher-level
    variables above don't cover. Each rule is ONE statement type; for compound AND/OR/NOT
    logic, extend custom-rules.tf using the pattern documented at the top of that file.
      name                     - Unique rule name
      priority                 - Integer priority, unique across all rules in the ACL
      action                   - "allow", "block", or "count"
      statement_type           - "byte_match" | "size_constraint" | "sqli_match" | "xss_match"
      field_to_match_type      - "uri_path" | "query_string" | "single_header" | "all_query_arguments" | "method" | "body"
      header_name              - Header name, required when field_to_match_type = "single_header"
      text_transformation_type - e.g. "NONE", "LOWERCASE", "URL_DECODE", "HTML_ENTITY_DECODE"
      search_string            - Required for statement_type = "byte_match"
      positional_constraint    - Required for statement_type = "byte_match": EXACTLY|STARTS_WITH|ENDS_WITH|CONTAINS|CONTAINS_WORD
      comparison_operator      - Required for statement_type = "size_constraint": EQ|NE|LE|LT|GE|GT
      size                     - Required for statement_type = "size_constraint" (bytes)
  EOT
  type = list(object({
    name                     = string
    priority                 = number
    action                   = string
    statement_type           = string
    field_to_match_type      = string
    header_name              = optional(string, "")
    text_transformation_type = optional(string, "NONE")
    search_string            = optional(string, "")
    positional_constraint    = optional(string, "CONTAINS")
    comparison_operator      = optional(string, "GT")
    size                     = optional(number, 0)
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.custom_rules : contains(["allow", "block", "count"], r.action)])
    error_message = "action for each custom_rule must be 'allow', 'block' or 'count'."
  }
  validation {
    condition = alltrue([
      for r in var.custom_rules :
      contains(["byte_match", "size_constraint", "sqli_match", "xss_match"], r.statement_type)
    ])
    error_message = "statement_type must be one of byte_match, size_constraint, sqli_match, xss_match."
  }
}

##############################################
# ASSOCIATIONS  (see association.tf, REGIONAL scope only)
##############################################

variable "resource_arns" {
  description = "List of resource ARNs (ALB, API Gateway stage, AppSync API) to associate with this Web ACL. Only valid when var.scope = REGIONAL; for CLOUDFRONT, attach the web_acl_arn output directly to the distribution instead."
  type        = list(string)
  default     = []
}

##############################################
# LOGGING  (see logging.tf)
##############################################

variable "enable_logging" {
  description = "Whether to enable Web ACL logging to the destinations in var.log_destination_configs."
  type        = bool
  default     = false
}

variable "log_destination_configs" {
  description = "List of ARNs (Kinesis Data Firehose, CloudWatch Logs log group, or S3 bucket) to send WAF logs to. Required when enable_logging = true."
  type        = list(string)
  default     = []
}

variable "logging_filter" {
  description = <<-EOT
    Optional logging filter to control which requests get logged.
      default_behavior - "KEEP" or "DROP"
      filters          - list of { behavior, requirement, conditions } - leave filters = [] to log everything
  EOT
  type = object({
    default_behavior = string
    filters = list(object({
      behavior    = string
      requirement = string
      conditions  = list(object({ action_condition = string }))
    }))
  })
  default = {
    default_behavior = "KEEP"
    filters          = []
  }
}

variable "redacted_fields" {
  description = "List of field types to redact from logs, e.g. [\"uri_path\", \"query_string\", \"single_header:authorization\"]."
  type        = list(string)
  default     = []
}

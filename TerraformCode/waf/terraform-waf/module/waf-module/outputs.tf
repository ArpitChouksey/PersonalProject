output "web_acl_id" {
  description = "ID of the WAFv2 Web ACL."
  value       = aws_wafv2_web_acl.this.id
}

output "web_acl_arn" {
  description = "ARN of the WAFv2 Web ACL. Attach this to a CloudFront distribution's web_acl_id when scope = CLOUDFRONT."
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_name" {
  description = "Name of the WAFv2 Web ACL."
  value       = aws_wafv2_web_acl.this.name
}

output "web_acl_capacity" {
  description = "Consumed WCU (Web ACL Capacity Unit) count for the Web ACL."
  value       = aws_wafv2_web_acl.this.capacity
}

output "ip_set_ids" {
  description = "Map of IP set name to its ID."
  value       = { for k, v in aws_wafv2_ip_set.this : k => v.id }
}

output "ip_set_arns" {
  description = "Map of IP set name to its ARN."
  value       = { for k, v in aws_wafv2_ip_set.this : k => v.arn }
}

output "regex_pattern_set_ids" {
  description = "Map of regex pattern set name to its ID."
  value       = { for k, v in aws_wafv2_regex_pattern_set.this : k => v.id }
}

output "regex_pattern_set_arns" {
  description = "Map of regex pattern set name to its ARN."
  value       = { for k, v in aws_wafv2_regex_pattern_set.this : k => v.arn }
}

output "association_ids" {
  description = "Map of resource ARN to Web ACL association ID (REGIONAL scope only)."
  value       = { for k, v in aws_wafv2_web_acl_association.this : k => v.id }
}

output "logging_configuration_id" {
  description = "ID of the logging configuration, if enabled."
  value       = try(aws_wafv2_web_acl_logging_configuration.this[0].id, null)
}

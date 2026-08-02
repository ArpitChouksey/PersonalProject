output "web_acl_arn" {
  description = "ARN of the deployed Web ACL."
  value       = module.waf.web_acl_arn
}

output "web_acl_id" {
  description = "ID of the deployed Web ACL."
  value       = module.waf.web_acl_id
}

output "web_acl_capacity" {
  description = "Consumed WCU capacity of the deployed Web ACL."
  value       = module.waf.web_acl_capacity
}

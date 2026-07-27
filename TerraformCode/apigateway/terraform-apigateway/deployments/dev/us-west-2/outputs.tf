###############################################################
# Outputs
###############################################################

output "http_api_ids" {
  value = module.apigateway.http_api_ids
}

output "http_api_endpoints" {
  value = module.apigateway.http_api_endpoints
}

output "rest_api_ids" {
  value = module.apigateway.rest_api_ids
}

output "rest_api_execution_arns" {
  value = module.apigateway.rest_api_execution_arns
}

output "websocket_api_ids" {
  value = module.apigateway.websocket_api_ids
}

output "websocket_api_endpoints" {
  value = module.apigateway.websocket_api_endpoints
}

output "integration_ids" {
  value = module.apigateway.integration_ids
}

output "authorizer_ids" {
  value = module.apigateway.authorizer_ids
}

output "log_group_names" {
  value = module.apigateway.log_group_names
}

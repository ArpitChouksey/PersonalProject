###############################################################
# HTTP APIs
###############################################################

output "http_api_ids" {
  description = "HTTP API IDs"

  value = {
    for key, api in aws_apigatewayv2_api.http :
    key => api.id
  }
}

output "http_api_arns" {
  description = "HTTP API ARNs"

  value = {
    for key, api in aws_apigatewayv2_api.http :
    key => api.arn
  }
}

output "http_api_execution_arns" {
  description = "HTTP API Execution ARNs"

  value = {
    for key, api in aws_apigatewayv2_api.http :
    key => api.execution_arn
  }
}

output "http_api_endpoints" {
  description = "HTTP API Invoke URLs"

  value = {
    for key, stage in aws_apigatewayv2_stage.http :
    key => stage.invoke_url
  }
}

###############################################################
# REST APIs
###############################################################

output "rest_api_ids" {
  description = "REST API IDs"

  value = {
    for key, api in aws_api_gateway_rest_api.rest :
    key => api.id
  }
}

output "rest_api_execution_arns" {
  description = "REST API Execution ARNs"

  value = {
    for key, api in aws_api_gateway_rest_api.rest :
    key => api.execution_arn
  }
}

###############################################################
# WebSocket APIs
###############################################################

output "websocket_api_ids" {
  description = "WebSocket API IDs"

  value = {
    for key, api in aws_apigatewayv2_api.websocket :
    key => api.id
  }
}

output "websocket_api_arns" {
  description = "WebSocket API ARNs"

  value = {
    for key, api in aws_apigatewayv2_api.websocket :
    key => api.arn
  }
}

output "websocket_api_execution_arns" {
  description = "WebSocket API Execution ARNs"

  value = {
    for key, api in aws_apigatewayv2_api.websocket :
    key => api.execution_arn
  }
}

output "websocket_api_endpoints" {
  description = "WebSocket API Endpoints"

  value = {
    for key, stage in aws_apigatewayv2_stage.websocket :
    key => stage.invoke_url
  }
}

###############################################################
# Stages
###############################################################

output "http_stage_names" {
  value = {
    for key, stage in aws_apigatewayv2_stage.http :
    key => stage.name
  }
}

output "rest_stage_names" {
  value = {
    for key, stage in aws_api_gateway_stage.rest :
    key => stage.stage_name
  }
}

output "websocket_stage_names" {
  value = {
    for key, stage in aws_apigatewayv2_stage.websocket :
    key => stage.name
  }
}

###############################################################
# Domains
###############################################################

output "http_custom_domains" {
  value = {
    for key, domain in aws_apigatewayv2_domain_name.http :
    key => domain.domain_name
  }
}

output "rest_custom_domains" {
  value = {
    for key, domain in aws_api_gateway_domain_name.rest :
    key => domain.domain_name
  }
}

output "websocket_custom_domains" {
  value = {
    for key, domain in aws_apigatewayv2_domain_name.websocket :
    key => domain.domain_name
  }
}

###############################################################
# VPC Links
###############################################################

output "http_vpc_links" {
  value = {
    for key, link in aws_apigatewayv2_vpc_link.http :
    key => link.id
  }
}

output "rest_vpc_links" {
  value = {
    for key, link in aws_api_gateway_vpc_link.rest :
    key => link.id
  }
}

###############################################################
# Integrations
###############################################################

output "integration_ids" {
  description = "All integration IDs"

  value = local.integration_ids
}

###############################################################
# Authorizers
###############################################################

output "authorizer_ids" {
  description = "All authorizer IDs"

  value = local.authorizer_ids
}

###############################################################
# CloudWatch Log Groups
###############################################################

output "log_group_names" {
  value = merge(

    {
      for key, log in aws_cloudwatch_log_group.http :
      key => log.name
    },

    {
      for key, log in aws_cloudwatch_log_group.rest :
      key => log.name
    },

    {
      for key, log in aws_cloudwatch_log_group.websocket :
      key => log.name
    }

  )
}

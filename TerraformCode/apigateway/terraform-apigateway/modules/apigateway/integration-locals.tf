###############################################################
# Integration ID Lookup
###############################################################

locals {

  #############################################################
  # Lambda
  #############################################################

  lambda_integration_ids = {

    for key, integration in aws_apigatewayv2_integration.lambda :

    key => integration.id

  }

  #############################################################
  # ALB
  #############################################################

  alb_integration_ids = {

    for key, integration in aws_apigatewayv2_integration.alb :

    key => integration.id

  }

  #############################################################
  # NLB
  #############################################################

  nlb_integration_ids = {

    for key, integration in aws_apigatewayv2_integration.nlb :

    key => integration.id

  }

  #############################################################
  # HTTP
  #############################################################

  http_integration_ids = {

    for key, integration in aws_apigatewayv2_integration.http :

    key => integration.id

  }

  #############################################################
  # AWS Service
  #############################################################

  aws_service_integration_ids = {

    for key, integration in aws_apigatewayv2_integration.aws_service :

    key => integration.id

  }

  #############################################################
  # Combined Lookup
  #############################################################

  integration_ids = merge(

    local.lambda_integration_ids,

    local.alb_integration_ids,

    local.nlb_integration_ids,

    local.http_integration_ids,

    local.aws_service_integration_ids

  )

}

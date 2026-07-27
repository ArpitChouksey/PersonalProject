###############################################################
# WebSocket API Deployments
###############################################################

resource "aws_apigatewayv2_deployment" "websocket" {

  for_each = local.websocket_apis

  #############################################################
  # API
  #############################################################

  api_id = aws_apigatewayv2_api.websocket[
    each.key
  ].id

  #############################################################
  # Force Redeployment
  #############################################################

  triggers = {

    redeployment = sha1(jsonencode({

      routes        = try(each.value.routes, [])

      integrations  = try(each.value.integrations, [])

      authorizers   = try(each.value.authorizers, [])

    }))

  }

  #############################################################
  # Lifecycle
  #############################################################

  lifecycle {

    create_before_destroy = true

  }

  #############################################################
  # Dependencies
  #############################################################

  depends_on = [

    aws_apigatewayv2_route.websocket,

    aws_apigatewayv2_authorizer.websocket,

    aws_apigatewayv2_integration.lambda,

    aws_apigatewayv2_integration.alb,

    aws_apigatewayv2_integration.nlb,

    aws_apigatewayv2_integration.http,

    aws_apigatewayv2_integration.aws_service

  ]

}

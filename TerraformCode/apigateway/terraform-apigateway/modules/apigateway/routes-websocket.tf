###############################################################
# WebSocket API Routes
###############################################################

locals {

  websocket_routes = {

    for route in flatten([

      for api_key, api in local.websocket_apis : [

        for item in api.routes : merge(item, {

          api_key = api_key

        })

      ]

    ]) :

    "${route.api_key}-${route.route_key}" => route

  }

}

###############################################################
# Routes
###############################################################

resource "aws_apigatewayv2_route" "websocket" {

  for_each = local.websocket_routes

  #############################################################
  # API
  #############################################################

  api_id = aws_apigatewayv2_api.websocket[each.value.api_key].id

  #############################################################
  # Route
  #############################################################

  route_key = each.value.route_key

  #############################################################
  # Integration
  #############################################################

  target = format(
    "integrations/%s",
    local.integration_ids[
      format(
        "%s-%s",
        each.value.api_key,
        each.value.integration
      )
    ]
  )

  #############################################################
  # Authorization
  #############################################################

  authorization_type = try(
    each.value.authorization.type,
    "NONE"
  )

  authorizer_id = try(
    local.authorizer_ids[
      format(
        "%s-%s",
        each.value.api_key,
        each.value.authorization.name
      )
    ],
    null
  )

  authorization_scopes = try(
    each.value.authorization.scopes,
    null
  )

  #############################################################
  # API Key Required
  #############################################################

  api_key_required = try(
    each.value.api_key_required,
    false
  )

  #############################################################
  # Operation Name
  #############################################################

  operation_name = try(
    each.value.operation_name,
    null
  )

  #############################################################
  # Model Selection
  #############################################################

  model_selection_expression = try(
    each.value.model_selection_expression,
    null
  )

  #############################################################
  # Request Models
  #############################################################

  request_models = try(
    each.value.request_models,
    null
  )

  #############################################################
  # Route Response Selection
  #############################################################

  route_response_selection_expression = try(
    each.value.route_response_selection_expression,
    null
  )

  #############################################################
  # Lifecycle
  #############################################################

  lifecycle {

    create_before_destroy = true

    precondition {

      condition = contains(
        keys(local.integration_ids),
        format(
          "%s-%s",
          each.value.api_key,
          each.value.integration
        )
      )

      error_message = "Referenced integration does not exist."

    }

  }

  #############################################################
  # Dependencies
  #############################################################

  depends_on = [

    aws_apigatewayv2_integration.lambda,
    aws_apigatewayv2_integration.alb,
    aws_apigatewayv2_integration.nlb,
    aws_apigatewayv2_integration.http,
    aws_apigatewayv2_integration.aws_service

  ]

}

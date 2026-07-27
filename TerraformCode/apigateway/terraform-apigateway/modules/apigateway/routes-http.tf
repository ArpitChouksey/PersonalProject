###############################################################
# HTTP API Routes
###############################################################

locals {

  http_routes = {

    for route in flatten([

      for api_key, api in local.http_apis : [

        for item in api.routes : merge(item, {

          api_key = api_key

        })

      ]

    ]) :

    "${route.api_key}-${route.method}-${route.path}" => route

  }

}

###############################################################
# Routes
###############################################################

resource "aws_apigatewayv2_route" "http" {

  for_each = local.http_routes

  #############################################################
  # API
  #############################################################

  api_id = aws_apigatewayv2_api.http[each.value.api_key].id

  #############################################################
  # Route
  #############################################################

  route_key = format(
    "%s %s",
    upper(each.value.method),
    each.value.path
  )

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
  # API Key
  #############################################################

  api_key_required = try(
    each.value.api_key_required,
    false
  )

  #############################################################
  # Operation
  #############################################################

  operation_name = try(
    each.value.operation_name,
    null
  )

  #############################################################
  # Models
  #############################################################

  model_selection_expression = try(
    each.value.model_selection_expression,
    null
  )

  request_models = try(
    each.value.request_models,
    null
  )

  #############################################################
  # Request Parameters
  #############################################################

  dynamic "request_parameter" {

    for_each = try(each.value.request_parameters, {})

    content {

      request_parameter_key = request_parameter.key

      required = request_parameter.value.required

    }

  }

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

  depends_on = [

    aws_apigatewayv2_integration.lambda,
    aws_apigatewayv2_integration.alb,
    aws_apigatewayv2_integration.nlb,
    aws_apigatewayv2_integration.http,
    aws_apigatewayv2_integration.aws_service

  ]

}

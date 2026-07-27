###############################################################
# HTTP API - Lambda Integrations
###############################################################

locals {

  lambda_integrations = {

    for integration in flatten([

      for api_key, api in local.v2_apis : [

        for item in api.integrations : merge(item, {

          api_key = api_key

        })

      ]

    ]) :

    "${integration.api_key}-${integration.name}" => integration

    if upper(integration.type) == "LAMBDA"

  }

}

###############################################################
# Lambda Permission
###############################################################

resource "aws_lambda_permission" "apigateway" {

  for_each = local.lambda_integrations

  statement_id = "AllowExecutionFromAPIGateway-${replace(each.key, "-", "")}"

  action = "lambda:InvokeFunction"

  function_name = each.value.config.function_arn

  principal = "apigateway.amazonaws.com"

  source_arn = "${contains(keys(local.http_apis), each.value.api_key) ? aws_apigatewayv2_api.http[each.value.api_key].execution_arn : aws_apigatewayv2_api.websocket[each.value.api_key].execution_arn}/*/*"

}

###############################################################
# HTTP API Integration
###############################################################

resource "aws_apigatewayv2_integration" "lambda" {

  for_each = local.lambda_integrations

  #############################################################
  # API
  #############################################################

  api_id = contains(keys(local.http_apis), each.value.api_key) ? aws_apigatewayv2_api.http[each.value.api_key].id : aws_apigatewayv2_api.websocket[each.value.api_key].id

  #############################################################
  # Integration
  #############################################################

  integration_type = "AWS_PROXY"

  integration_method = "POST"

  integration_uri = each.value.config.function_arn

  payload_format_version = try(
    each.value.options.payload_format_version,
    contains(keys(local.http_apis), each.value.api_key) ? "2.0" : "1.0"
  )

  timeout_milliseconds = try(
    each.value.options.timeout_milliseconds,
    29000
  )

  description = try(
    each.value.description,
    null
  )

  #############################################################
  # Lifecycle
  #############################################################

  lifecycle {

    create_before_destroy = true

    precondition {

      condition = try(
        each.value.config.function_arn,
        ""
      ) != ""

      error_message = "Lambda integration requires config.function_arn."

    }

  }

  #############################################################
  # Dependency
  #############################################################

  depends_on = [

    aws_lambda_permission.apigateway

  ]

}

###############################################################
# HTTP API - AWS Service Integrations
###############################################################

locals {

  aws_service_integrations = {

    for integration in flatten([

      for api_key, api in local.v2_apis : [

        for item in api.integrations : merge(item, {

          api_key = api_key

        })

      ]

    ]) :

    "${integration.api_key}-${integration.name}" => integration

    if upper(integration.type) == "AWS"

  }

}

###############################################################
# AWS Service Integration
###############################################################

resource "aws_apigatewayv2_integration" "aws_service" {

  for_each = local.aws_service_integrations

  #############################################################
  # API
  #############################################################

  api_id = contains(keys(local.http_apis), each.value.api_key) ? aws_apigatewayv2_api.http[each.value.api_key].id : aws_apigatewayv2_api.websocket[each.value.api_key].id

  #############################################################
  # Integration
  #############################################################

  integration_type = "AWS_PROXY"

  integration_subtype = each.value.config.integration_subtype

  credentials_arn = each.value.config.credentials_arn

  payload_format_version = try(
    each.value.options.payload_format_version,
    "1.0"
  )

  timeout_milliseconds = try(
    each.value.options.timeout_milliseconds,
    29000
  )

  #############################################################
  # Request Parameters
  #############################################################

  request_parameters = try(
    each.value.config.request_parameters,
    {}
  )

  #############################################################
  # Description
  #############################################################

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
        each.value.config.integration_subtype,
        ""
      ) != ""

      error_message = "AWS integration requires config.integration_subtype."

    }

    precondition {

      condition = try(
        each.value.config.credentials_arn,
        ""
      ) != ""

      error_message = "AWS integration requires config.credentials_arn."

    }

  }

}

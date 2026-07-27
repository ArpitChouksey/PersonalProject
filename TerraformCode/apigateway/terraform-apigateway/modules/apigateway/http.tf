###############################################################
# HTTP API - HTTP/HTTPS Integrations
###############################################################

locals {

  http_integrations = {

    for integration in flatten([

      for api_key, api in local.v2_apis : [

        for item in api.integrations : merge(item, {
          api_key = api_key
        })

      ]

    ]) :

    "${integration.api_key}-${integration.name}" => integration

    if upper(integration.type) == "HTTP"

  }

}

###############################################################
# HTTP Proxy Integration
###############################################################

resource "aws_apigatewayv2_integration" "http" {

  for_each = local.http_integrations

  #############################################################
  # API
  #############################################################

  api_id = contains(keys(local.http_apis), each.value.api_key) ? aws_apigatewayv2_api.http[each.value.api_key].id : aws_apigatewayv2_api.websocket[each.value.api_key].id

  #############################################################
  # Integration
  #############################################################

  integration_type = "HTTP_PROXY"

  integration_uri = each.value.config.url

  integration_method = try(
    each.value.options.integration_method,
    "ANY"
  )

  payload_format_version = try(
    each.value.options.payload_format_version,
    "1.0"
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
  # Optional VPC Link
  #############################################################

  connection_type = try(
    each.value.options.connection_type,
    "INTERNET"
  )

  connection_id = try(
    each.value.options.connection_type,
    "INTERNET"
  ) == "VPC_LINK" ? coalesce(
    try(each.value.config.vpc_link_id, null),
    try(local.v2_apis[each.value.api_key].vpc.vpc_link_id, null)
  ) : null

  #############################################################
  # TLS Configuration
  #############################################################

  dynamic "tls_config" {

    for_each = try(each.value.options.server_name_to_verify, "") != "" ? [1] : []

    content {

      server_name_to_verify = each.value.options.server_name_to_verify

    }

  }

  #############################################################
  # Request Parameters
  #############################################################

  request_parameters = try(
    each.value.options.request_parameters,
    null
  )

  #############################################################
  # Lifecycle
  #############################################################

  lifecycle {

    create_before_destroy = true

    precondition {

      condition = try(
        each.value.config.url,
        ""
      ) != ""

      error_message = "HTTP integration requires config.url."

    }

  }

}

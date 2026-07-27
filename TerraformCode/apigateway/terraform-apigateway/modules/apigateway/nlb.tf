###############################################################
# HTTP API - NLB Integrations
###############################################################

locals {

  nlb_integrations = {

    for integration in flatten([

      for api_key, api in local.v2_apis : [

        for item in api.integrations : merge(item, {

          api_key = api_key

        })

      ]

    ]) :

    "${integration.api_key}-${integration.name}" => integration

    if upper(integration.type) == "NLB"

  }

}

###############################################################
# HTTP API Integration
###############################################################

resource "aws_apigatewayv2_integration" "nlb" {

  for_each = local.nlb_integrations

  #############################################################
  # API
  #############################################################

  api_id = contains(keys(local.http_apis), each.value.api_key) ? aws_apigatewayv2_api.http[each.value.api_key].id : aws_apigatewayv2_api.websocket[each.value.api_key].id

  #############################################################
  # Integration
  #############################################################

  integration_type = "HTTP_PROXY"

  integration_method = try(
    each.value.options.integration_method,
    "ANY"
  )

  integration_uri = each.value.config.listener_arn

  #############################################################
  # VPC Link
  #############################################################

  connection_type = "VPC_LINK"

  connection_id = coalesce(
    try(each.value.config.vpc_link_id, null),
    try(each.value.options.vpc_link_id, null),
    try(local.v2_apis[each.value.api_key].vpc.vpc_link_id, null)
  )

  #############################################################
  # Payload Format
  #############################################################

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
  # TLS Configuration
  #############################################################

  dynamic "tls_config" {

    for_each = try(each.value.options.server_name_to_verify, "") != "" ? [1] : []

    content {

      server_name_to_verify = each.value.options.server_name_to_verify

    }

  }

  #############################################################
  # Lifecycle
  #############################################################

  lifecycle {

    create_before_destroy = true

    precondition {

      condition = try(
        each.value.config.listener_arn,
        ""
      ) != ""

      error_message = "NLB integration requires config.listener_arn."

    }

    precondition {

      condition = coalesce(
        try(each.value.config.vpc_link_id, null),
        try(each.value.options.vpc_link_id, null),
        try(local.v2_apis[each.value.api_key].vpc.vpc_link_id, null)
      ) != null

      error_message = "NLB integration requires a VPC Link ID."

    }

  }

}

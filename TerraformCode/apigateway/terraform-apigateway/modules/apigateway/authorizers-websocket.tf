###############################################################
# WebSocket API Authorizers
###############################################################

locals {

  websocket_authorizers = {

    for authorizer in flatten([

      for api_key, api in local.websocket_apis : [

        for item in try(api.authorizers, []) : merge(item, {

          api_key = api_key

        })

      ]

    ]) :

    "${authorizer.api_key}-${authorizer.name}" => authorizer

  }

}

###############################################################
# WebSocket API Authorizers
###############################################################

resource "aws_apigatewayv2_authorizer" "websocket" {

  for_each = local.websocket_authorizers

  #############################################################
  # API
  #############################################################

  api_id = aws_apigatewayv2_api.websocket[
    each.value.api_key
  ].id

  #############################################################
  # Basic
  #############################################################

  name = each.value.name

  authorizer_type = "REQUEST"

  #############################################################
  # Identity Source
  #############################################################

  identity_sources = try(

    each.value.identity_sources,

    [
      "route.request.header.Authorization"
    ]

  )

  #############################################################
  # Lambda Authorizer
  #############################################################

  authorizer_uri = each.value.authorizer_uri

  authorizer_credentials_arn = try(
    each.value.authorizer_credentials_arn,
    null
  )

  authorizer_payload_format_version = try(
    each.value.authorizer_payload_format_version,
    "2.0"
  )

  enable_simple_responses = try(
    each.value.enable_simple_responses,
    false
  )

  authorizer_result_ttl_in_seconds = try(
    each.value.authorizer_result_ttl_in_seconds,
    300
  )

  #############################################################
  # Lifecycle
  #############################################################

  lifecycle {

    create_before_destroy = true

    precondition {

      condition = try(
        each.value.authorizer_uri,
        ""
      ) != ""

      error_message = "WebSocket REQUEST authorizer requires authorizer_uri."

    }

  }

}

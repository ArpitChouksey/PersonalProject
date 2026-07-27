###############################################################
# HTTP API Authorizers
###############################################################

locals {

  http_authorizers = {

    for authorizer in flatten([

      for api_key, api in local.http_apis : [

        for item in try(api.authorizers, []) : merge(item, {

          api_key = api_key

        })

      ]

    ]) :

    "${authorizer.api_key}-${authorizer.name}" => authorizer

  }

}

###############################################################
# HTTP API Authorizers
###############################################################

resource "aws_apigatewayv2_authorizer" "http" {

  for_each = local.http_authorizers

  #############################################################
  # API
  #############################################################

  api_id = aws_apigatewayv2_api.http[each.value.api_key].id

  #############################################################
  # Basic
  #############################################################

  name = each.value.name

  authorizer_type = upper(each.value.type)

  identity_sources = try(
    each.value.identity_sources,
    [
      "$request.header.Authorization"
    ]
  )

  #############################################################
  # Lambda Request Authorizer
  #############################################################

  authorizer_uri = try(
    each.value.authorizer_uri,
    null
  )

  authorizer_payload_format_version = try(
    each.value.authorizer_payload_format_version,
    upper(each.value.type) == "REQUEST" ? "2.0" : null
  )

  enable_simple_responses = try(
    each.value.enable_simple_responses,
    null
  )

  authorizer_result_ttl_in_seconds = try(
    each.value.authorizer_result_ttl_in_seconds,
    300
  )

  #############################################################
  # JWT Authorizer
  #############################################################

  dynamic "jwt_configuration" {

    for_each = upper(each.value.type) == "JWT" ? [1] : []

    content {

      audience = try(
        each.value.jwt_configuration.audience,
        []
      )

      issuer = each.value.jwt_configuration.issuer

    }

  }

  #############################################################
  # Lifecycle
  #############################################################

  lifecycle {

    create_before_destroy = true

    precondition {

      condition = contains(
        [
          "JWT",
          "REQUEST"
        ],
        upper(each.value.type)
      )

      error_message = "Supported HTTP API authorizer types are JWT and REQUEST."

    }

    precondition {

      condition = upper(each.value.type) != "JWT" || try(
        each.value.jwt_configuration.issuer,
        ""
      ) != ""

      error_message = "JWT authorizer requires jwt_configuration.issuer."

    }

    precondition {

      condition = upper(each.value.type) != "REQUEST" || try(
        each.value.authorizer_uri,
        ""
      ) != ""

      error_message = "REQUEST authorizer requires authorizer_uri."

    }

  }

}

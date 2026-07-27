###############################################################
# REST API Authorizers
###############################################################

locals {

  rest_authorizers = {

    for authorizer in flatten([

      for api_key, api in local.rest_apis : [

        for item in try(api.authorizers, []) : merge(item, {

          api_key = api_key

        })

      ]

    ]) :

    "${authorizer.api_key}-${authorizer.name}" => authorizer

  }

}

###############################################################
# REST API Authorizers
###############################################################

resource "aws_api_gateway_authorizer" "rest" {

  for_each = local.rest_authorizers

  #############################################################
  # API
  #############################################################

  rest_api_id = aws_api_gateway_rest_api.rest[
    each.value.api_key
  ].id

  #############################################################
  # Basic
  #############################################################

  name = each.value.name

  type = upper(each.value.type)

  #############################################################
  # Identity Source
  #############################################################

  identity_source = try(
    join(",", each.value.identity_sources),
    "method.request.header.Authorization"
  )

  #############################################################
  # Lambda Authorizer
  #############################################################

  authorizer_uri = try(
    each.value.authorizer_uri,
    null
  )

  authorizer_credentials = try(
    each.value.authorizer_credentials,
    null
  )

  authorizer_result_ttl_in_seconds = try(
    each.value.authorizer_result_ttl_in_seconds,
    300
  )

  #############################################################
  # Cognito
  #############################################################

  provider_arns = (
    upper(each.value.type) == "COGNITO_USER_POOLS"
    ? each.value.provider_arns
    : null
  )

  #############################################################
  # Validation Expression
  #############################################################

  identity_validation_expression = try(
    each.value.identity_validation_expression,
    null
  )

  #############################################################
  # Lifecycle
  #############################################################

  lifecycle {

    create_before_destroy = true

    precondition {

      condition = contains(
        [
          "TOKEN",
          "REQUEST",
          "COGNITO_USER_POOLS"
        ],
        upper(each.value.type)
      )

      error_message = "Supported REST authorizer types are TOKEN, REQUEST and COGNITO_USER_POOLS."

    }

    precondition {

      condition = upper(each.value.type) != "TOKEN" || try(
        each.value.authorizer_uri,
        ""
      ) != ""

      error_message = "TOKEN authorizer requires authorizer_uri."

    }

    precondition {

      condition = upper(each.value.type) != "REQUEST" || try(
        each.value.authorizer_uri,
        ""
      ) != ""

      error_message = "REQUEST authorizer requires authorizer_uri."

    }

    precondition {

      condition = upper(each.value.type) != "COGNITO_USER_POOLS" || length(
        try(each.value.provider_arns, [])
      ) > 0

      error_message = "COGNITO_USER_POOLS authorizer requires provider_arns."

    }

  }

}

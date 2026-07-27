###############################################################
# HTTP API Gateway
###############################################################

resource "aws_apigatewayv2_api" "http" {

  for_each = local.http_apis

  name          = each.value.api.name
  description   = each.value.api.description
  protocol_type = "HTTP"

  #############################################################
  # Disable default execute-api endpoint (Optional)
  #############################################################

  disable_execute_api_endpoint = try(
    each.value.endpoint.disable_execute_api_endpoint,
    false
  )

  #############################################################
  # CORS
  #############################################################

  dynamic "cors_configuration" {

    for_each = try(each.value.cors.enabled, false) ? [1] : []

    content {

      allow_credentials = try(each.value.cors.allow_credentials, false)

      allow_headers = try(
        each.value.cors.allow_headers,
        []
      )

      allow_methods = try(
        each.value.cors.allow_methods,
        []
      )

      allow_origins = try(
        each.value.cors.allow_origins,
        []
      )

      expose_headers = try(
        each.value.cors.expose_headers,
        []
      )

      max_age = try(
        each.value.cors.max_age,
        0
      )
    }
  }

  #############################################################
  # Tags
  #############################################################

  tags = each.value.tags

  #############################################################
  # Lifecycle
  #############################################################

  lifecycle {

    create_before_destroy = true

  }

}

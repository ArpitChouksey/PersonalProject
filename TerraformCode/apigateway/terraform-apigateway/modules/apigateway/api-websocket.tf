###############################################################
# WebSocket API Gateway (API Gateway V2)
###############################################################

resource "aws_apigatewayv2_api" "websocket" {

  for_each = local.websocket_apis

  #############################################################
  # Basic Configuration
  #############################################################

  name          = each.value.api.name
  protocol_type = "WEBSOCKET"

  description = try(
    each.value.api.description,
    null
  )

  #############################################################
  # WebSocket Route Selection Expression
  #############################################################

  route_selection_expression = try(
    each.value.api.route_selection_expression,
    "$request.body.action"
  )

  #############################################################
  # API Version
  #############################################################

  version = try(
    each.value.api.version,
    null
  )

  #############################################################
  # API Key Selection Expression
  #############################################################

  api_key_selection_expression = try(
    each.value.api.api_key_selection_expression,
    null
  )

  #############################################################
  # Disable Execute API Endpoint
  #############################################################

  disable_execute_api_endpoint = try(
    each.value.endpoint.disable_execute_api_endpoint,
    false
  )

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

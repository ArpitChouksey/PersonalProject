###############################################################
# API Gateway Logging
###############################################################

locals {

  #############################################################
  # HTTP Logging
  #############################################################

  http_logging = {

    for key, api in local.http_apis :

    key => api

    if try(api.logging.enabled, false)

  }

  #############################################################
  # REST Logging
  #############################################################

  rest_logging = {

    for key, api in local.rest_apis :

    key => api

    if try(api.logging.enabled, false)

  }

  #############################################################
  # WebSocket Logging
  #############################################################

  websocket_logging = {

    for key, api in local.websocket_apis :

    key => api

    if try(api.logging.enabled, false)

  }

}

###############################################################
# HTTP Log Group
###############################################################

resource "aws_cloudwatch_log_group" "http" {

  for_each = local.http_logging

  name = try(
    each.value.logging.log_group_name,
    "/aws/apigateway/${each.key}"
  )

  retention_in_days = try(
    each.value.logging.retention_in_days,
    30
  )

  kms_key_id = try(
    each.value.logging.kms_key_id,
    null
  )

  tags = merge(
    local.common_tags,
    try(each.value.tags, {})
  )

}

###############################################################
# REST Log Group
###############################################################

resource "aws_cloudwatch_log_group" "rest" {

  for_each = local.rest_logging

  name = try(
    each.value.logging.log_group_name,
    "/aws/apigateway/${each.key}"
  )

  retention_in_days = try(
    each.value.logging.retention_in_days,
    30
  )

  kms_key_id = try(
    each.value.logging.kms_key_id,
    null
  )

  tags = merge(
    local.common_tags,
    try(each.value.tags, {})
  )

}

###############################################################
# WebSocket Log Group
###############################################################

resource "aws_cloudwatch_log_group" "websocket" {

  for_each = local.websocket_logging

  name = try(
    each.value.logging.log_group_name,
    "/aws/apigateway/${each.key}"
  )

  retention_in_days = try(
    each.value.logging.retention_in_days,
    30
  )

  kms_key_id = try(
    each.value.logging.kms_key_id,
    null
  )

  tags = merge(
    local.common_tags,
    try(each.value.tags, {})
  )

}

###############################################################
# HTTP Stage Logging
#
# Access logging is configured directly on the primary stage
# resource in stage-http.tf via a dynamic "access_log_settings"
# block — a second aws_apigatewayv2_stage resource here would
# target the same api_id + name and collide at apply time.
###############################################################

###############################################################
# WebSocket Stage Logging
#
# Access logging is configured directly on the primary stage
# resource in stage-websocket.tf via a dynamic
# "access_log_settings" block, for the same reason as HTTP above.
###############################################################

###############################################################
# REST Method Settings
###############################################################

resource "aws_api_gateway_method_settings" "rest" {

  for_each = local.rest_logging

  rest_api_id = aws_api_gateway_rest_api.rest[
    each.key
  ].id

  stage_name = aws_api_gateway_stage.rest[
    each.key
  ].stage_name

  method_path = "*/*"

  settings {

    metrics_enabled = try(
      each.value.logging.metrics_enabled,
      true
    )

    logging_level = try(
      each.value.logging.logging_level,
      "INFO"
    )

    data_trace_enabled = try(
      each.value.logging.data_trace_enabled,
      false
    )

    throttling_rate_limit = try(
      each.value.logging.throttling_rate_limit,
      null
    )

    throttling_burst_limit = try(
      each.value.logging.throttling_burst_limit,
      null
    )

  }

}

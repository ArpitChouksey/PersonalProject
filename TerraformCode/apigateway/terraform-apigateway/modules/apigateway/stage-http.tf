###############################################################
# HTTP API Stage
###############################################################

resource "aws_apigatewayv2_stage" "http" {

  for_each = local.http_apis

  #############################################################
  # API
  #############################################################

  api_id = aws_apigatewayv2_api.http[each.key].id

  #############################################################
  # Stage
  #############################################################

  name = try(
    each.value.stage.name,
    "$default"
  )

  auto_deploy = try(
    each.value.stage.auto_deploy,
    true
  )

  #############################################################
  # Default Route Settings
  #############################################################

  default_route_settings {

    detailed_metrics_enabled = try(
      each.value.logging.metrics,
      true
    )

    throttling_burst_limit = try(
      each.value.stage.throttling_burst_limit,
      null
    )

    throttling_rate_limit = try(
      each.value.stage.throttling_rate_limit,
      null
    )

  }

  #############################################################
  # Stage Variables (Optional)
  #############################################################

  stage_variables = try(
    each.value.stage.variables,
    {}
  )

  #############################################################
  # Access Logs
  #
  # Merged directly into this stage rather than a second
  # aws_apigatewayv2_stage resource — API Gateway v2 only allows
  # one stage per name per API, so two Terraform resources both
  # targeting the same api_id + name collide at apply time.
  #############################################################

  dynamic "access_log_settings" {

    for_each = try(each.value.logging.enabled, false) ? [1] : []

    content {

      destination_arn = aws_cloudwatch_log_group.http[each.key].arn

      format = try(
        each.value.logging.format,
        jsonencode({
          requestId      = "$context.requestId"
          requestTime    = "$context.requestTime"
          httpMethod     = "$context.httpMethod"
          routeKey       = "$context.routeKey"
          status         = "$context.status"
          protocol       = "$context.protocol"
          responseLength = "$context.responseLength"
          ip             = "$context.identity.sourceIp"
        })
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

  #############################################################
  # Explicit Dependency
  #############################################################

  depends_on = [
    aws_apigatewayv2_api.http
  ]

}

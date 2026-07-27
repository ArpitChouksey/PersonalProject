###############################################################
# REST API Stage (API Gateway V1)
###############################################################

resource "aws_api_gateway_stage" "rest" {

  for_each = local.rest_apis

  #############################################################
  # API
  #############################################################

  rest_api_id = aws_api_gateway_rest_api.rest[each.key].id

  deployment_id = aws_api_gateway_deployment.rest[each.key].id

  #############################################################
  # Stage
  #############################################################

  stage_name = try(
    each.value.stage.name,
    "dev"
  )

  #############################################################
  # Stage Variables
  #############################################################

  variables = try(
    each.value.stage.variables,
    {}
  )

  #############################################################
  # X-Ray Tracing
  #############################################################

  xray_tracing_enabled = try(
    each.value.logging.xray,
    false
  )

  #############################################################
  # Cache Cluster
  #############################################################

  cache_cluster_enabled = try(
    each.value.stage.cache_cluster_enabled,
    false
  )

  cache_cluster_size = try(
    each.value.stage.cache_cluster_size,
    null
  )

  #############################################################
  # Documentation Version
  #############################################################

  documentation_version = try(
    each.value.stage.documentation_version,
    null
  )

  #############################################################
  # Client Certificate
  #############################################################

  client_certificate_id = try(
    each.value.stage.client_certificate_id,
    null
  )

  #############################################################
  # Description
  #############################################################

  description = try(
    each.value.stage.description,
    null
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

  #############################################################
  # Dependencies
  #############################################################

  depends_on = [
    aws_api_gateway_rest_api.rest,
    aws_api_gateway_deployment.rest
  ]

}

###############################################################
# Domain Names
###############################################################

locals {

  #############################################################
  # HTTP APIs with Domain
  #############################################################

  http_domains = {

    for key, api in local.http_apis :

    key => api

    if try(api.domain.enabled, false)

  }

  #############################################################
  # REST APIs with Domain
  #############################################################

  rest_domains = {

    for key, api in local.rest_apis :

    key => api

    if try(api.domain.enabled, false)

  }

  #############################################################
  # WebSocket APIs with Domain
  #############################################################

  websocket_domains = {

    for key, api in local.websocket_apis :

    key => api

    if try(api.domain.enabled, false)

  }

}

###############################################################
# HTTP API Domain
###############################################################

resource "aws_apigatewayv2_domain_name" "http" {

  for_each = local.http_domains

  domain_name = each.value.domain.name

  domain_name_configuration {

    certificate_arn = each.value.domain.certificate_arn

    endpoint_type = try(
      each.value.domain.endpoint_type,
      "REGIONAL"
    )

    security_policy = try(
      each.value.domain.security_policy,
      "TLS_1_2"
    )

  }

  dynamic "mutual_tls_authentication" {

    for_each = try(each.value.domain.mtls.truststore_uri, null) != null ? [1] : []

    content {

      truststore_uri = each.value.domain.mtls.truststore_uri

      truststore_version = try(
        each.value.domain.mtls.truststore_version,
        null
      )

    }

  }

  tags = merge(

    local.common_tags,

    try(each.value.tags, {})

  )

}

###############################################################
# HTTP API Mapping
###############################################################

resource "aws_apigatewayv2_api_mapping" "http" {

  for_each = local.http_domains

  api_id = aws_apigatewayv2_api.http[
    each.key
  ].id

  domain_name = aws_apigatewayv2_domain_name.http[
    each.key
  ].id

  stage = aws_apigatewayv2_stage.http[
    each.key
  ].id

  api_mapping_key = try(
    each.value.domain.base_path,
    null
  )

}

###############################################################
# WebSocket API Domain
###############################################################

resource "aws_apigatewayv2_domain_name" "websocket" {

  for_each = local.websocket_domains

  domain_name = each.value.domain.name

  domain_name_configuration {

    certificate_arn = each.value.domain.certificate_arn

    endpoint_type = "REGIONAL"

    security_policy = try(
      each.value.domain.security_policy,
      "TLS_1_2"
    )

  }

  tags = merge(

    local.common_tags,

    try(each.value.tags, {})

  )

}

###############################################################
# WebSocket API Mapping
###############################################################

resource "aws_apigatewayv2_api_mapping" "websocket" {

  for_each = local.websocket_domains

  api_id = aws_apigatewayv2_api.websocket[
    each.key
  ].id

  domain_name = aws_apigatewayv2_domain_name.websocket[
    each.key
  ].id

  stage = aws_apigatewayv2_stage.websocket[
    each.key
  ].id

  api_mapping_key = try(
    each.value.domain.base_path,
    null
  )

}

###############################################################
# REST API Domain
###############################################################

resource "aws_api_gateway_domain_name" "rest" {

  for_each = local.rest_domains

  domain_name = each.value.domain.name

  certificate_arn = try(
    upper(each.value.domain.endpoint_type) == "EDGE"
      ? each.value.domain.certificate_arn
      : null,
    null
  )

  regional_certificate_arn = try(
    upper(each.value.domain.endpoint_type) == "REGIONAL"
      ? each.value.domain.certificate_arn
      : null,
    null
  )

  security_policy = try(
    each.value.domain.security_policy,
    "TLS_1_2"
  )

  endpoint_configuration {

    types = [

      try(
        upper(each.value.domain.endpoint_type),
        "REGIONAL"
      )

    ]

  }

  tags = merge(

    local.common_tags,

    try(each.value.tags, {})

  )

}

###############################################################
# REST Base Path Mapping
###############################################################

resource "aws_api_gateway_base_path_mapping" "rest" {

  for_each = local.rest_domains

  api_id = aws_api_gateway_rest_api.rest[
    each.key
  ].id

  domain_name = aws_api_gateway_domain_name.rest[
    each.key
  ].domain_name

  stage_name = aws_api_gateway_stage.rest[
    each.key
  ].stage_name

  base_path = try(
    each.value.domain.base_path,
    null
  )

}

###############################################################
# Optional Route53 Alias
###############################################################

resource "aws_route53_record" "api_domain" {

  for_each = {

    for key, api in merge(

      local.http_domains,

      local.websocket_domains,

      local.rest_domains

    ) :

    key => api

    if try(api.domain.route53.enabled, false)

  }

  zone_id = each.value.domain.route53.zone_id

  name = each.value.domain.name

  type = "A"

  alias {

    name = (
      contains(keys(local.http_domains), each.key) ?
      aws_apigatewayv2_domain_name.http[each.key].domain_name_configuration[0].target_domain_name :

      contains(keys(local.websocket_domains), each.key) ?
      aws_apigatewayv2_domain_name.websocket[each.key].domain_name_configuration[0].target_domain_name :

      aws_api_gateway_domain_name.rest[each.key].regional_domain_name
    )

    zone_id = (
      contains(keys(local.http_domains), each.key) ?
      aws_apigatewayv2_domain_name.http[each.key].domain_name_configuration[0].hosted_zone_id :

      contains(keys(local.websocket_domains), each.key) ?
      aws_apigatewayv2_domain_name.websocket[each.key].domain_name_configuration[0].hosted_zone_id :

      aws_api_gateway_domain_name.rest[each.key].regional_zone_id
    )

    evaluate_target_health = false

  }

}

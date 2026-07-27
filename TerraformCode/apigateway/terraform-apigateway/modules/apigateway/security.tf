###############################################################
# Security
###############################################################

locals {

  #############################################################
  # REST APIs requiring API Keys
  #############################################################

  api_keys = {

    for key, api in local.rest_apis :

    key => api

    if try(api.security.api_key.enabled, false)

  }

  #############################################################
  # Usage Plans
  #############################################################

  usage_plans = {

    for key, api in local.rest_apis :

    key => api

    if try(api.security.usage_plan.enabled, false)

  }

}

###############################################################
# API Keys
###############################################################

resource "aws_api_gateway_api_key" "this" {

  for_each = local.api_keys

  name = try(

    each.value.security.api_key.name,

    "${local.name_prefix}-${each.key}"

  )

  description = try(

    each.value.security.api_key.description,

    null

  )

  enabled = try(

    each.value.security.api_key.enabled,

    true

  )

  value = try(

    each.value.security.api_key.value,

    null

  )

  tags = merge(

    local.common_tags,

    try(each.value.tags, {})

  )

}

###############################################################
# Usage Plans
###############################################################

resource "aws_api_gateway_usage_plan" "this" {

  for_each = local.usage_plans

  name = try(

    each.value.security.usage_plan.name,

    "${local.name_prefix}-${each.key}"

  )

  description = try(

    each.value.security.usage_plan.description,

    null

  )

  #############################################################
  # API Stage
  #############################################################

  api_stages {

    api_id = aws_api_gateway_rest_api.rest[
      each.key
    ].id

    stage = aws_api_gateway_stage.rest[
      each.key
    ].stage_name

  }

  #############################################################
  # Quota
  #############################################################

  dynamic "quota_settings" {

    for_each = try(
      each.value.security.usage_plan.quota, null
    ) != null ? [1] : []

    content {

      limit = each.value.security.usage_plan.quota.limit

      offset = try(
        each.value.security.usage_plan.quota.offset,
        null
      )

      period = each.value.security.usage_plan.quota.period

    }

  }

  #############################################################
  # Throttle
  #############################################################

  dynamic "throttle_settings" {

    for_each = try(
      each.value.security.usage_plan.throttle, null
    ) != null ? [1] : []

    content {

      burst_limit = each.value.security.usage_plan.throttle.burst_limit

      rate_limit = each.value.security.usage_plan.throttle.rate_limit

    }

  }

  tags = merge(

    local.common_tags,

    try(each.value.tags, {})

  )

}

###############################################################
# Usage Plan Key
###############################################################

resource "aws_api_gateway_usage_plan_key" "this" {

  for_each = local.usage_plans

  key_id = aws_api_gateway_api_key.this[
    each.key
  ].id

  key_type = "API_KEY"

  usage_plan_id = aws_api_gateway_usage_plan.this[
    each.key
  ].id

}

###############################################################
# WAF Association - HTTP API
###############################################################

resource "aws_wafv2_web_acl_association" "http" {

  for_each = {

    for key, api in local.http_apis :

    key => api

    if try(api.security.waf.enabled, false)

  }

  resource_arn = aws_apigatewayv2_stage.http[
    each.key
  ].arn

  web_acl_arn = each.value.security.waf.web_acl_arn

}

###############################################################
# WAF Association - REST API
###############################################################

resource "aws_wafv2_web_acl_association" "rest" {

  for_each = {

    for key, api in local.rest_apis :

    key => api

    if try(api.security.waf.enabled, false)

  }

  resource_arn = aws_api_gateway_stage.rest[
    each.key
  ].arn

  web_acl_arn = each.value.security.waf.web_acl_arn

}

###############################################################
# WAF Association - WebSocket API
###############################################################

resource "aws_wafv2_web_acl_association" "websocket" {

  for_each = {

    for key, api in local.websocket_apis :

    key => api

    if try(api.security.waf.enabled, false)

  }

  resource_arn = aws_apigatewayv2_stage.websocket[
    each.key
  ].arn

  web_acl_arn = each.value.security.waf.web_acl_arn

}

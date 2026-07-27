###############################################################
# API Gateway Networking
###############################################################

locals {

  #############################################################
  # HTTP APIs requiring VPC Link
  #############################################################

  http_vpc_links = {

    for key, api in local.http_apis :

    key => api

    if try(api.vpc.enabled, false)

  }

  #############################################################
  # REST APIs requiring VPC Link
  #############################################################

  rest_vpc_links = {

    for key, api in local.rest_apis :

    key => api

    if try(api.vpc.enabled, false)

  }

}

###############################################################
# HTTP API VPC Link
###############################################################

resource "aws_apigatewayv2_vpc_link" "http" {

  for_each = {

    for key, api in local.http_vpc_links :

    key => api

    if try(api.vpc.create_vpc_link, false)

  }

  #############################################################
  # Basic
  #############################################################

  name = try(

    each.value.vpc.name,

    "${local.name_prefix}-${each.key}"

  )

  #############################################################
  # Networking
  #############################################################

  subnet_ids = each.value.vpc.subnet_ids

  security_group_ids = try(

    each.value.vpc.security_group_ids,

    []

  )

  #############################################################
  # Tags
  #############################################################

  tags = merge(

    local.common_tags,

    try(each.value.tags, {})

  )

}

###############################################################
# REST API VPC Link
###############################################################

resource "aws_api_gateway_vpc_link" "rest" {

  for_each = {

    for key, api in local.rest_vpc_links :

    key => api

    if try(api.vpc.create_vpc_link, false)

  }

  #############################################################
  # Basic
  #############################################################

  name = try(

    each.value.vpc.name,

    "${local.name_prefix}-${each.key}"

  )

  #############################################################
  # REST VPC Link
  #############################################################

  target_arns = each.value.vpc.target_arns

  #############################################################
  # Tags
  #############################################################

  tags = merge(

    local.common_tags,

    try(each.value.tags, {})

  )

}

###############################################################
# VPC Link Lookup
###############################################################

locals {

  #############################################################
  # HTTP
  #############################################################

  http_vpc_link_ids = {

    for key, api in local.http_vpc_links :

    key => try(

      aws_apigatewayv2_vpc_link.http[key].id,

      api.vpc.vpc_link_id

    )

  }

  #############################################################
  # REST
  #############################################################

  rest_vpc_link_ids = {

    for key, api in local.rest_vpc_links :

    key => try(

      aws_api_gateway_vpc_link.rest[key].id,

      api.vpc.vpc_link_id

    )

  }

}

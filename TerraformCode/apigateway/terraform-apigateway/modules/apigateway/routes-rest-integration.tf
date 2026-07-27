###############################################################
# REST API Integrations
###############################################################

###############################################################
# Lambda Permission (LAMBDA integrations only)
###############################################################

resource "aws_lambda_permission" "rest_apigateway" {

  for_each = {

    for key, route in local.rest_method_integrations :

    key => route

    if route.integration_def != null && upper(route.integration_def.type) == "LAMBDA"

  }

  statement_id = "AllowExecutionFromAPIGatewayREST${md5(each.key)}"

  action = "lambda:InvokeFunction"

  function_name = each.value.integration_def.config.function_arn

  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.rest[each.value.api_key].execution_arn}/*/*"

}

###############################################################
# Integration
#
# Type mapping:
#   LAMBDA         -> AWS_PROXY   (Lambda proxy integration)
#   ALB / NLB      -> HTTP_PROXY  (via VPC Link)
#   HTTP           -> HTTP_PROXY  (public/private HTTP endpoint)
#   AWS            -> AWS         (native service integration,
#                                   non-proxy — requires request/
#                                   response mapping)
###############################################################

resource "aws_api_gateway_integration" "rest" {

  for_each = local.rest_method_integrations

  #############################################################
  # API / Resource / Method
  #############################################################

  rest_api_id = aws_api_gateway_rest_api.rest[each.value.api_key].id

  resource_id = local.rest_resource_ids[each.value.resource_key]

  http_method = aws_api_gateway_method.rest[each.key].http_method

  #############################################################
  # Integration Type
  #############################################################

  type = (
    upper(each.value.integration_def.type) == "LAMBDA" ? "AWS_PROXY" :
    contains(["ALB", "NLB", "HTTP"], upper(each.value.integration_def.type)) ? "HTTP_PROXY" :
    "AWS"
  )

  #############################################################
  # Integration HTTP Method
  # Lambda proxy always invokes via POST; everything else
  # forwards the caller's method.
  #############################################################

  integration_http_method = upper(each.value.integration_def.type) == "LAMBDA" ? "POST" : upper(each.value.method)

  #############################################################
  # URI
  #############################################################

  uri = (
    upper(each.value.integration_def.type) == "LAMBDA" ?
    "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${each.value.integration_def.config.function_arn}/invocations" :

    contains(["ALB", "NLB"], upper(each.value.integration_def.type)) ?
    each.value.integration_def.config.listener_arn :

    upper(each.value.integration_def.type) == "HTTP" ?
    each.value.integration_def.config.url :

    # AWS service integration — REST API (v1) has no v2-style
    # "integration_subtype" quick-create. Supply the full target
    # URI directly, e.g.:
    #   arn:aws:apigateway:{region}:sqs:path/{account_id}/{queue_name}
    #   arn:aws:apigateway:{region}:events:action/PutEvents
    try(each.value.integration_def.config.uri, null)
  )

  #############################################################
  # VPC Link (ALB / NLB)
  #############################################################

  connection_type = contains(["ALB", "NLB"], upper(each.value.integration_def.type)) ? "VPC_LINK" : "INTERNET"

  connection_id = contains(["ALB", "NLB"], upper(each.value.integration_def.type)) ? (
    each.value.integration_def.config.vpc_link_id
  ) : null

  #############################################################
  # Credentials (AWS service integrations)
  #############################################################

  credentials = try(
    each.value.integration_def.config.credentials_arn,
    null
  )

  #############################################################
  # Request Templates / Passthrough (AWS integrations)
  #############################################################

  request_templates = try(
    each.value.integration_def.config.request_templates,
    null
  )

  passthrough_behavior = upper(each.value.integration_def.type) == "AWS" ? "WHEN_NO_MATCH" : null

  #############################################################
  # Timeout
  #############################################################

  timeout_milliseconds = try(
    each.value.integration_def.options.timeout_milliseconds,
    29000
  )

  #############################################################
  # Lifecycle
  #############################################################

  lifecycle {

    create_before_destroy = true

    precondition {

      condition = each.value.integration_def != null

      error_message = "Referenced REST integration does not exist."

    }

  }

  depends_on = [

    aws_lambda_permission.rest_apigateway

  ]

}

###############################################################
# REST API Method Responses
#
# Created for every route regardless of integration type — valid
# and recommended even for proxy integrations (Lambda, ALB, NLB,
# HTTP), since it's what allows CORS/response headers to be
# declared at the method level.
###############################################################

resource "aws_api_gateway_method_response" "rest" {

  for_each = local.rest_method_responses

  #############################################################
  # API / Resource / Method
  #############################################################

  rest_api_id = aws_api_gateway_rest_api.rest[each.value.api_key].id

  resource_id = local.rest_resource_ids[each.value.resource_key]

  http_method = aws_api_gateway_method.rest[each.value.method_key].http_method

  #############################################################
  # Status Code
  #############################################################

  status_code = each.value.status_code

  #############################################################
  # Models / Parameters
  #############################################################

  response_models = each.value.response_models

  response_parameters = each.value.response_parameters

  depends_on = [

    aws_api_gateway_method.rest

  ]

}

###############################################################
# REST API Integration Responses
###############################################################

resource "aws_api_gateway_integration_response" "rest" {

  for_each = local.rest_integration_responses

  #############################################################
  # API / Resource / Method
  #############################################################

  rest_api_id = aws_api_gateway_rest_api.rest[each.value.api_key].id

  resource_id = local.rest_resource_ids[each.value.resource_key]

  http_method = aws_api_gateway_method.rest[each.value.method_key].http_method

  #############################################################
  # Status Code / Selection Pattern
  #############################################################

  status_code = each.value.status_code

  selection_pattern = each.value.selection_pattern

  #############################################################
  # Templates / Parameters
  #############################################################

  response_templates = each.value.response_templates

  response_parameters = each.value.response_parameters

  depends_on = [

    aws_api_gateway_integration.rest,
    aws_api_gateway_method_response.rest

  ]

}

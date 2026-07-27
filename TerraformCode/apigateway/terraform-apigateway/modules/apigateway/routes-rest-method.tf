###############################################################
# REST API Methods
###############################################################

resource "aws_api_gateway_method" "rest" {

  for_each = local.rest_methods

  #############################################################
  # API / Resource
  #############################################################

  rest_api_id = aws_api_gateway_rest_api.rest[each.value.api_key].id

  resource_id = local.rest_resource_ids[each.value.resource_key]

  #############################################################
  # HTTP Method
  #############################################################

  http_method = upper(each.value.method)

  #############################################################
  # Authorization
  #
  # `authorization` on a route is either NONE, AWS_IAM, or the
  # `name` of an entry in the API's `authorizers` block — mirrors
  # how authorizers-rest.tf keys aws_api_gateway_authorizer.rest.
  #############################################################

  authorization = (
    upper(try(each.value.authorization, "NONE")) == "NONE" ? "NONE" :
    upper(try(each.value.authorization, "")) == "AWS_IAM" ? "AWS_IAM" :
    try(
      upper(local.rest_authorizers["${each.value.api_key}-${each.value.authorization}"].type),
      "CUSTOM"
    )
  )

  authorizer_id = try(
    aws_api_gateway_authorizer.rest["${each.value.api_key}-${each.value.authorization}"].id,
    null
  )

  #############################################################
  # API Key
  #############################################################

  api_key_required = try(
    each.value.api_key_required,
    false
  )

  #############################################################
  # Request Parameters
  #############################################################

  request_parameters = try(
    {
      for k, v in each.value.request_parameters :
      k => v.required
    },
    null
  )

  #############################################################
  # Lifecycle
  #############################################################

  lifecycle {

    create_before_destroy = true

    precondition {

      condition = contains(
        keys(local.rest_resource_ids),
        each.value.resource_key
      )

      error_message = "REST resource for this route does not exist."

    }

  }

}

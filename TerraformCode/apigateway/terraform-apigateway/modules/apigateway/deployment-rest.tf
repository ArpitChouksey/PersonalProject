###############################################################
# REST API Deployments
###############################################################

resource "aws_api_gateway_deployment" "rest" {

  for_each = local.rest_apis

  #############################################################
  # REST API
  #############################################################

  rest_api_id = aws_api_gateway_rest_api.rest[
    each.key
  ].id

  #############################################################
  # Force Redeployment
  #############################################################

  triggers = {

    redeployment = sha1(jsonencode({

      routes        = try(each.value.routes, [])

      integrations  = try(each.value.integrations, [])

      authorizers   = try(each.value.authorizers, [])

      # Hash the actual OpenAPI file content (not just the YAML
      # pointer to it) so editing the swagger file itself forces
      # a redeploy, same as editing routes/integrations does.
      openapi_body = try(each.value.import.enabled, false) ? filesha1(
        "${var.openapi_definition_path}/${each.value.import.openapi_file}"
      ) : ""

    }))

  }

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

    aws_api_gateway_resource.rest_d1,
    aws_api_gateway_resource.rest_d2,
    aws_api_gateway_resource.rest_d3,
    aws_api_gateway_resource.rest_d4,
    aws_api_gateway_resource.rest_d5,
    aws_api_gateway_resource.rest_d6,

    aws_api_gateway_method.rest,

    aws_api_gateway_integration.rest,

    aws_api_gateway_authorizer.rest,

    time_sleep.rest_import_settle

  ]

}

###############################################################
# Lambda Permission for OpenAPI-Imported REST APIs
#
# The YAML-driven routes engine (routes-rest-integration.tf)
# grants Lambda permissions per-route automatically, but it has
# no visibility into an imported API's routes -- those live
# inside an opaque swagger `body` string, not in Terraform-visible
# YAML. Without this, an imported API's Lambda integration(s)
# would deploy successfully but fail at request time with a 500,
# since API Gateway would never actually be allowed to invoke the
# function.
#
# Set `import.grant_lambda_invoke` to the Lambda function ARN (or
# a list of ARNs) referenced inside the swagger file to have this
# module grant the permission automatically.
###############################################################

locals {

  rest_import_lambda_grants = {

    for pair in flatten([

      for api_key, api in local.rest_apis : [

        for arn in flatten([try(api.import.grant_lambda_invoke, [])]) : {

          key         = "${api_key}-${arn}"
          api_key     = api_key
          function_arn = arn

        }

      ] if try(api.import.enabled, false)

    ]) :

    pair.key => pair

  }

}

resource "aws_lambda_permission" "rest_import" {

  for_each = local.rest_import_lambda_grants

  statement_id = "AllowExecutionFromAPIGatewayImport${md5(each.key)}"

  action = "lambda:InvokeFunction"

  function_name = each.value.function_arn

  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.rest[each.value.api_key].execution_arn}/*/*"

}

###############################################################
# REST API Integration Responses (Normalized)
#
# Only applies to the AWS (non-proxy) integration type. AWS_PROXY
# (Lambda) and HTTP_PROXY (ALB/NLB/HTTP) pass the backend response
# straight through to the caller and do not support — and will
# fail to plan/apply — an integration_response resource.
###############################################################

locals {

  rest_integration_responses = {

    for pair in flatten([

      for key, route in local.rest_method_integrations : [

        for response in route.responses : {

          key = "${key}-${response.status_code}"

          api_key = route.api_key

          resource_key = route.resource_key

          method_key = key

          status_code = response.status_code

          selection_pattern = try(response.selection_pattern, null)

          response_templates = try(response.response_templates, { "application/json" = "" })

          response_parameters = try(response.integration_response_parameters, {})

        }

      ] if route.integration_def != null && upper(route.integration_def.type) == "AWS"

    ]) :

    pair.key => pair

  }

}

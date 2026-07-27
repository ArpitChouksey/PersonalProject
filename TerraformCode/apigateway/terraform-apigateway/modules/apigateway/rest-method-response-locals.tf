###############################################################
# REST API Method Responses (Normalized)
###############################################################

locals {

  rest_method_responses = {

    for pair in flatten([

      for key, route in local.rest_methods : [

        for response in route.responses : {

          key = "${key}-${response.status_code}"

          api_key = route.api_key

          resource_key = route.resource_key

          method_key = key

          status_code = response.status_code

          response_models = try(response.response_models, { "application/json" = "Empty" })

          response_parameters = try(response.response_parameters, {})

        }

      ]

    ]) :

    pair.key => pair

  }

}

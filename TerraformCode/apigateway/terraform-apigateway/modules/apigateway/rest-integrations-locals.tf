###############################################################
# REST API Integration Definitions (Normalized)
###############################################################

locals {

  rest_integration_defs = {

    for integration in flatten([

      for api_key, api in local.rest_apis : [

        for item in try(api.integrations, []) : merge(item, {

          api_key = api_key

        })

      ]

    ]) :

    "${integration.api_key}-${integration.name}" => integration

  }

  #############################################################
  # Each route merged with its resolved integration definition
  #############################################################

  rest_method_integrations = {

    for key, route in local.rest_methods :

    key => merge(route, {

      integration_def = try(
        local.rest_integration_defs["${route.api_key}-${route.integration}"],
        null
      )

    })

  }

}

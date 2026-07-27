###############################################################
# REST API Routes (Normalized)
###############################################################

locals {

  #############################################################
  # REST APIs using OpenAPI/Swagger import supply their own
  # resources/methods/integrations via the imported body -- the
  # manual routes/resource-tree engine below must skip them,
  # otherwise both approaches would try to manage the same API.
  #############################################################

  rest_apis_yaml_routes = {

    for k, v in local.rest_apis :

    k => v

    if !try(v.import.enabled, false)

  }

  rest_routes = {

    for route in flatten([

      for api_key, api in local.rest_apis_yaml_routes : [

        for item in api.routes : merge(item, {

          api_key = api_key

        })

      ]

    ]) :

    "${route.api_key}-${route.method}-${route.path}" => route

  }

}

###############################################################
# REST API Methods (Normalized)
###############################################################

locals {

  rest_methods = {

    for key, route in local.rest_routes :

    key => merge(route, {

      resource_key = "${route.api_key}-${route.path}"

      # Defaults to a single 200 response when the route doesn't
      # declare one — needed so every method still gets a valid
      # method_response, regardless of integration type.
      responses = try(route.responses, [{ status_code = "200" }])

    })

  }

}

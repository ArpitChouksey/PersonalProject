###############################################################
# REST API Gateway (API Gateway V1)
###############################################################

resource "aws_api_gateway_rest_api" "rest" {

  for_each = local.rest_apis

  #############################################################
  # Basic Configuration
  #############################################################

  name        = each.value.api.name
  description = each.value.api.description

  #############################################################
  # API Endpoint Configuration
  #############################################################

  endpoint_configuration {

    types = [
      upper(
        try(
          each.value.endpoint.type,
          "REGIONAL"
        )
      )
    ]

  }

  #############################################################
  # Binary Media Types
  #############################################################

  binary_media_types = try(
    each.value.api.binary_media_types,
    null
  )

  #############################################################
  # Minimum Compression Size
  #############################################################

  minimum_compression_size = try(
    each.value.api.minimum_compression_size,
    null
  )

  #############################################################
  # Disable Execute API Endpoint
  #############################################################

  disable_execute_api_endpoint = try(
    each.value.endpoint.disable_execute_api_endpoint,
    false
  )

  #############################################################
  # API Key Source
  #############################################################

  api_key_source = try(
    each.value.security.api_key_source,
    "HEADER"
  )

  #############################################################
  # OpenAPI / Swagger Import
  #
  # When `import.enabled` is set, the API's resources/methods/
  # integrations come from an OpenAPI (Swagger) file instead of
  # the routes/integrations engine -- see rest-routes-locals.tf,
  # which excludes these APIs from the manual resource-tree build
  # so the two approaches don't collide on the same API.
  #############################################################

  body = try(each.value.import.enabled, false) ? (
    length(try(each.value.import.template_vars, {})) > 0 ?
    templatefile(
      "${var.openapi_definition_path}/${each.value.import.openapi_file}",
      each.value.import.template_vars
    ) :
    file("${var.openapi_definition_path}/${each.value.import.openapi_file}")
  ) : null

  put_rest_api_mode = try(each.value.import.enabled, false) ? try(
    each.value.import.mode,
    "merge"
  ) : null

  #############################################################
  # Tags
  #############################################################

  tags = each.value.tags

  #############################################################
  # Lifecycle
  #############################################################

  lifecycle {

    create_before_destroy = true

  }

}

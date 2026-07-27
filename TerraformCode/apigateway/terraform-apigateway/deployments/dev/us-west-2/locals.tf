###############################################################
# Locals
###############################################################

locals {

  #############################################################
  # Absolute path to apigatewayconfig/apis
  #
  # fileset() inside the reusable module resolves a relative
  # path against the MODULE's own directory, not this root
  # module's directory, so this must be computed here (where
  # path.root correctly means "this deployment's directory")
  # and passed in as an already-absolute string.
  #############################################################

  api_definition_path = "${path.root}/../../../apigatewayconfig/apis"

  #############################################################
  # Absolute path to apigatewayconfig/openapi -- same reasoning,
  # for APIs using OpenAPI/Swagger import.
  #############################################################

  openapi_definition_path = "${path.root}/../../../apigatewayconfig/openapi"

}

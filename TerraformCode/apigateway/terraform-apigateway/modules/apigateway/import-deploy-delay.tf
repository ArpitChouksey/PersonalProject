###############################################################
# Settling Delay for OpenAPI-Imported REST APIs
#
# Addresses: "The REST API doesn't contain any methods" on
# aws_api_gateway_deployment immediately after an OpenAPI import.
#
# This is a known, documented category of AWS timing issue:
# ImportRestApi can report success before AWS's backend has fully
# finished registering the imported resources/methods, and
# CreateDeployment can fire before that registration settles --
# even on a retried apply, since the import itself (not just the
# deployment) is what's racing.
#
# Only applies to import-enabled APIs -- the manually-built
# routes/resources/methods engine doesn't have this race, since
# each of those pieces is created as its own explicitly-ordered
# Terraform resource rather than one opaque import call.
###############################################################

resource "time_sleep" "rest_import_settle" {

  for_each = {
    for k, v in local.rest_apis :
    k => v
    if try(v.import.enabled, false)
  }

  create_duration = "15s"

  triggers = {
    rest_api_id = aws_api_gateway_rest_api.rest[each.key].id
  }

  depends_on = [
    aws_api_gateway_rest_api.rest
  ]

}

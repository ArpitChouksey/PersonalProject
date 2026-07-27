###############################################################
# Authorizer Lookup
###############################################################

locals {

  http_authorizer_ids = {

    for key, authorizer in aws_apigatewayv2_authorizer.http :

    key => authorizer.id

  }

  authorizer_ids = merge(

    local.http_authorizer_ids

  )

}

###############################################################
# Local Values
###############################################################

locals {

  #############################################################
  # Common Project Information
  #############################################################

  project = lower(var.project_name)

  name_prefix = "${local.project}-${var.environment}"

  common_tags = merge(
    {
      Project           = var.project_name
      Environment       = var.environment
      Owner             = var.owner
      BusinessUnit      = var.business_unit
      CostCenter        = var.cost_center
      ManagedBy         = "Terraform"
      IaC               = "Terraform"
      Repository        = "Enterprise-Landing-Zone"
      TerraformVersion  = var.terraform_version
    },
    var.tags
  )

  availability_zones = [
    "${var.aws_region}a",
    "${var.aws_region}b",
    "${var.aws_region}c"
  ]

  #############################################################
  # Read API Definition Files
  #############################################################

  api_files = fileset(var.api_definition_path, "*.yaml")

  #############################################################
  # Decode YAML Files
  #############################################################

  raw_apis = {

    for file in local.api_files :

    trimsuffix(file, ".yaml") => yamldecode(
      file("${var.api_definition_path}/${file}")
    )

  }

  #############################################################
  # Normalize API Configuration
  #############################################################

  apis = {

    for api_name, api in local.raw_apis :

    api_name => {

      #########################################################
      # Enable
      #########################################################

      enabled = lookup(api, "enabled", true)

      #########################################################
      # Metadata
      #########################################################

      metadata = merge({

        owner        = ""

        team         = ""

        application  = ""

        project      = ""

        environment  = var.environment

        cost_center  = ""

      }, lookup(api, "metadata", {}))

      #########################################################
      # API
      #########################################################

      api = merge({

        name          = api_name

        description   = ""

        version       = "v1"

        protocol_type = "HTTP"

      }, lookup(api, "api", {}))

      #########################################################
      # Stage
      #########################################################

      stage = merge({

        name = "$default"

        auto_deploy = true

      }, lookup(api, "stage", {}))

      #########################################################
      # Endpoint
      #########################################################

      endpoint = merge({

        type = "REGIONAL"

      }, lookup(api, "endpoint", {}))

      #########################################################
      # CORS
      #########################################################

      cors = merge({

        enabled = false

        allow_origins = []

        allow_methods = []

        allow_headers = []

        expose_headers = []

        allow_credentials = false

        max_age = 0

      }, lookup(api, "cors", {}))

      #########################################################
      # Logging
      #########################################################

      logging = merge({

        access_logs = true

        execution_logs = true

        metrics = true

        xray = false

        retention_days = 30

      }, lookup(api, "logging", {}))

      #########################################################
      # Domain
      #########################################################

      domain = merge({

        enabled = false

        domain_name = ""

        certificate_arn = ""

        hosted_zone_id = ""

      }, lookup(api, "domain", {}))

      #########################################################
      # VPC
      #########################################################

      vpc = merge({

        enabled = false

        vpc_link_id = ""

      }, lookup(api, "vpc", {}))

      #########################################################
      # Security
      #########################################################

      security = merge({

        authorization = {

          default = "NONE"

        }

        api_key_required = false

      }, lookup(api, "security", {}))

      #########################################################
      # Authorizers
      #########################################################

      authorizers = lookup(api, "authorizers", [])

      #########################################################
      # Routes
      #########################################################

      routes = lookup(api, "routes", [])

      #########################################################
      # Integrations
      #########################################################

      integrations = lookup(api, "integrations", [])

      #########################################################
      # OpenAPI / Swagger Import
      #
      # This was missing entirely until now -- every field this
      # normalization block doesn't explicitly list gets silently
      # dropped from local.apis, since this is a field-by-field
      # reconstruction, not a raw passthrough of the decoded YAML.
      # That's why `import.enabled` always evaluated to false in
      # api-rest.tf regardless of what the YAML said: it was never
      # actually reachable.
      #########################################################

      import = lookup(api, "import", {})

      #########################################################
      # WAF
      #########################################################

      waf = merge({

        enabled = false

        web_acl_arn = ""

      }, lookup(api, "waf", {}))

      #########################################################
      # Tags
      #########################################################

      tags = merge(

        local.common_tags,

        lookup(api, "tags", {})

      )

    }

  }

  #############################################################
  # HTTP APIs
  #############################################################

  http_apis = {

    for k, v in local.apis :

    k => v

    if upper(v.api.protocol_type) == "HTTP" && v.enabled

  }

  #############################################################
  # REST APIs
  #############################################################

  rest_apis = {

    for k, v in local.apis :

    k => v

    if upper(v.api.protocol_type) == "REST" && v.enabled

  }

  #############################################################
  # WebSocket APIs
  #############################################################

  websocket_apis = {

    for k, v in local.apis :

    k => v

    if upper(v.api.protocol_type) == "WEBSOCKET" && v.enabled

  }

  #############################################################
  # HTTP + WebSocket combined
  #
  # Both protocols use the aws_apigatewayv2_* resource family and
  # share the same integration types (Lambda/ALB/NLB/HTTP/AWS),
  # so integration files loop over this combined set instead of
  # http_apis alone -- otherwise WebSocket routes have no
  # integration resource to actually point at.
  #############################################################

  v2_apis = merge(
    local.http_apis,
    local.websocket_apis
  )

}

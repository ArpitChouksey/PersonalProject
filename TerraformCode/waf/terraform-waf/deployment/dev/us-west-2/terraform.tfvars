aws_region = "us-west-2"

default_tags = {
  Environment = "dev"
  Project     = "security-platform"
  ManagedBy   = "terraform"
}

# Same shared policy file used by every dev deployment - see
# config/wafconfig/webacls/dev.yaml
webacl_config_file = "dev.yaml"

# ---- region/scope-specific values (not in the shared YAML) ----
scope = "REGIONAL"

resource_arns = [
  # e.g. "arn:aws:apigateway:us-west-2::/restapis/abcd1234/stages/dev"
]

log_destination_configs = [
  "arn:aws:firehose:us-west-2:111122223333:deliverystream/aws-waf-logs-dev"
]

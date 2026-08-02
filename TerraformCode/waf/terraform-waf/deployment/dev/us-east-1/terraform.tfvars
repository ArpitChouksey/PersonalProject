aws_region = "us-east-1"

default_tags = {
  Environment = "dev"
  Project     = "security-platform"
  ManagedBy   = "terraform"
}

# Same shared policy file used by every dev deployment - see
# config/wafconfig/webacls/dev.yaml
webacl_config_file = "dev.yaml"

# ---- region/scope-specific values (not in the shared YAML) ----
# CLOUDFRONT is only creatable in us-east-1 - that's the whole reason this
# region exists in the repo.
scope = "CLOUDFRONT"

resource_arns = []  # CLOUDFRONT doesn't use resource_arns - attach web_acl_arn
                     # to the distribution's web_acl_id instead

log_destination_configs = [
  "arn:aws:firehose:us-east-1:111122223333:deliverystream/aws-waf-logs-dev"
]

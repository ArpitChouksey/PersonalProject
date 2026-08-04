aws_region = "us-west-2"

default_tags = {
  Project   = "security-platform"
  ManagedBy = "terraform"
}

# ---------------------------------------------------------------------------
# Set exactly ONE role to true, matching whichever AWS account your current
# credentials point at right now.
# ---------------------------------------------------------------------------

# ROLE 1 - the common case: a single account's own detector.
enable_single_account      = true
single_account_config_file = "dev.yaml"   # or "prod.yaml", or your own new file

# ROLE 2 - one-time bootstrap, only if you need centralized multi-account
# findings (see ROLE 3). Most setups never turn this on.
enable_org_management = false

# ROLE 3 - the audit account that centralizes every member account's
# findings (e.g. all 100 accounts) into one place + one S3 export.
enable_audit_account = false

enable_publishing          = false
publishing_destination_arn = ""
publishing_kms_key_arn     = ""

# Set true to have this module create its own findings bucket in this
# same account (avoids any cross-account bucket policy). If false, set
# publishing_destination_arn to an existing bucket's ARN instead (same
# account or another - see external_bucket_policy_json output for the
# cross-account case).
create_publishing_bucket = false
publishing_bucket_name   = ""

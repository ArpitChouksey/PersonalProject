region      = "us-west-2"
name_prefix = "dev"

tags = {
  Environment = "dev"
  ManagedBy   = "terraform"
}

create_reports_bucket = true
reports_bucket_name   = "test-ssm-reports-dev-uswest2"   # e.g. myorg-ssm-reports-dev-us-west-2

# Per-OS patch settings (baseline, custom vs default, patch group, targets)
# now live in config/ssmconfig/dev/linux-custom.yaml and windows-custom.yaml -
# nothing patch-related needs to be set here anymore.

# true = create the compliance/non-compliance CSV report Lambda (+ both triggers)
# false = create only the core SSM pieces (documents/associations/inventory/patch)
enable_reporting_lambda = true

# Scan = report compliance only, no changes to instances.
# Install = actually install approved patches.
# Any OS not listed here falls back to its *-custom.yaml file's setting
# (default "Install"). Handy for a quick dry-run without editing YAML.
patch_operations = {
  linux   = "Install"
  windows = "Install"
}

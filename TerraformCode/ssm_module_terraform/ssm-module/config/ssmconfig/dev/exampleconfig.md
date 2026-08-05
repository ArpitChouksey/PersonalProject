# SSM Module - Config Guide

This folder holds the **policy** for one environment (`dev`). Nothing in
here is account-specific - bucket names, KMS keys, etc. live in
`deployment/dev/us-west-2/terraform.tfvars` instead, never here.

```
config/ssmconfig/dev/
├── dev.yaml              # documents, associations, inventory, feature toggles
├── linux-custom.yaml     # Linux patch policy
├── windows-custom.yaml   # Windows patch policy
└── <your-os>-custom.yaml # add more OSes by just dropping in a new file
```

---

## 1. dev.yaml - the shared, non-patch policy

```yaml
enable_documents: true
enable_associations: true
enable_inventory: true
enable_patch_compliance: true

documents:
  <logical_key>:
    name: "custom-example-command"       # actual SSM document name in AWS
    document_type: "Command"             # Command | Automation | Policy | ...
    document_format: "JSON"
    content: |
      { ... your SSM document body ... }

associations:
  <logical_key>:
    name: "enforce-baseline-config"      # association_name shown in console
    document_name: "custom-example-command"   # a name from `documents` above, OR an AWS-managed doc e.g. AWS-RunShellScript
    schedule_expression: "rate(7 days)"
    compliance_severity: "MEDIUM"
    targets:
      - key: "tag:Environment"
        values: ["dev", "staging"]       # one value is fine too - values: ["dev"]
    write_output_to_s3: true

inventory_targets:
  - key: "tag:Environment"
    values: ["dev", "staging"]
inventory_schedule_expression: "rate(1 day)"

reports_prefix: "Reports/"
reporting_lambda_schedule_expression: "rate(1 day)"
```

`<logical_key>` is just a map key you invent (e.g. `baseline_config`,
`example_command_doc`) - it becomes the Terraform resource index
(`aws_ssm_association.this["baseline_config"]`), it isn't sent to AWS.

---

## 2. `<os>-custom.yaml` - one file per operating system

Patch baselines in AWS are always scoped to a single OS, so each OS gets
its own file. **The filename is what tells Terraform which OS this is** -
`linux-custom.yaml` becomes the key `"linux"`, `windows-custom.yaml`
becomes `"windows"`. To add a third OS (say RHEL), just add
`rhel-custom.yaml` with the same shape below - no `.tf` file needs to
change.

```yaml
operating_system: "AMAZON_LINUX_2"   # must be a valid AWS patch-baseline OS value -
                                      # see the list at the bottom of this file

# ---- Baseline: default vs custom ----
# false (default) = use AWS's own predefined baseline for this OS. Nothing
#                    below this line matters if this is false.
# true             = build a baseline from the approval rules below.
create_custom_patch_baseline: false
patch_baseline_name: "dev-linux-custom-baseline"   # only used if the above is true

patch_approval_rules:
  - approve_after_days: 0          # 0 = approve immediately, no waiting period
    compliance_level: "CRITICAL"   # how this rule's patches are labeled if missing
    patch_filters:
      - key: "CLASSIFICATION"      # Linux keys: CLASSIFICATION, SEVERITY, PRODUCT, ...
        values: ["Security", "Bugfix", "Critical"]
  - approve_after_days: 0
    compliance_level: "HIGH"
    patch_filters:
      - key: "SEVERITY"
        values: ["Critical", "Important"]
patch_approved_patches: []   # explicit allow-list (KB IDs / package names) - usually left empty
patch_rejected_patches: []   # explicit deny-list - a patch you never want auto-installed

# ---- Which instances use this OS's baseline ----
# This is the ACTUAL mechanism AWS uses: an instance is patched under this
# baseline only if it's tagged  "Patch Group" = patch_group_name  below.
# patch_targets (further down) is a separate, additional filter used only
# by this module's maintenance window - both should agree on which
# instances you mean.
patch_group_name: "dev-linux-patch-group"

# "Scan" = report compliance only, no changes made to instances.
# "Install" = actually install approved patches.
# Can also be overridden per-OS from terraform.tfvars (patch_operations)
# without touching this file - see that file's comments.
patch_operation: "Install"

# How many matched instances patch AT THE SAME TIME.
# "1" = one at a time (sequential). "50%" = half the fleet. "100%" = all at once.
max_concurrency: "100%"
# How many failures tolerated before SSM stops launching new invocations.
max_errors: "10%"

# Tag-based targets for the maintenance window that runs patching.
# Multiple values per key = OR match. A single value is equally valid.
# Multiple target blocks (different keys) = AND across those keys.
patch_targets:
  - key: "tag:Environment"
    values: ["dev", "staging"]
  - key: "tag:OS"
    values: ["linux"]

maintenance_window_schedule: "cron(0 2 ? * SUN *)"   # when patching runs
maintenance_window_duration: 4                        # hours the window stays open
maintenance_window_cutoff: 1                           # hours before end to stop starting new tasks
```

### Common `operating_system` values
`AMAZON_LINUX_2`, `AMAZON_LINUX_2023`, `UBUNTU`, `REDHAT_ENTERPRISE_LINUX`,
`SUSE`, `CENTOS`, `DEBIAN`, `WINDOWS`, `MACOS`, `RASPBIAN`, `ROCKY_LINUX`.

### Common `patch_filters` keys
- Linux: `CLASSIFICATION`, `SEVERITY`, `PRODUCT`, `PRODUCT_FAMILY`, `PATCH_ID`
- Windows: `CLASSIFICATION` (e.g. `SecurityUpdates`, `CriticalUpdates`),
  `MSRC_SEVERITY` (e.g. `Critical`, `Important`), `PRODUCT`

---

## 3. Checklist for adding a brand-new custom policy

1. Copy `linux-custom.yaml` (or `windows-custom.yaml`) to
   `<yourOS>-custom.yaml`.
2. Set `operating_system` to the right AWS value.
3. Set `create_custom_patch_baseline: true` if you want your own rules
   (leave `false` to just use AWS's default for that OS).
4. Fill in `patch_approval_rules` / `patch_approved_patches` /
   `patch_rejected_patches` - only read if `create_custom_patch_baseline`
   is `true`.
5. Pick a unique `patch_group_name` (e.g. `dev-<os>-patch-group`) and make
   sure instances of that OS actually get tagged
   `"Patch Group" = <that value>` - nothing patches correctly without this
   tag matching.
6. Set `patch_targets` to whatever tags identify this OS's instances for
   the maintenance window (should describe the same instances as the
   `Patch Group` tag above).
7. `terraform plan` from `deployment/dev/us-west-2` - you should see one
   new baseline/patch group/maintenance window/target/task set, keyed by
   your new OS name, and nothing else in the plan should change.

## 4. Quick overrides that don't require editing these files

In `deployment/dev/us-west-2/terraform.tfvars`:

```hcl
# Flip Scan vs Install per OS without touching the YAML
patch_operations = {
  linux   = "Scan"
  windows = "Scan"
}
```

Everything else (baseline source, approval rules, targets, concurrency)
has to be changed in the relevant `<os>-custom.yaml` file - those are the
only two things kept in tfvars for a fast, low-risk toggle.

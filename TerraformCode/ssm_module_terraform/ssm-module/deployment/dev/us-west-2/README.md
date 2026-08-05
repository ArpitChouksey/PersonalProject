# SSM Module - Deployment Guide (dev / us-west-2)

This folder is what you actually `terraform apply`. It loads policy from
`../../../config/ssmconfig/dev/` and calls the reusable module in
`../../../module/ssm-module/`. You don't need to touch either of those to
run a normal deployment - just this folder's `terraform.tfvars`.

```
deployment/dev/us-west-2/
├── main.tf           # loads YAML, calls the module - you shouldn't need to edit this
├── variables.tf       # declares what terraform.tfvars can set
├── terraform.tfvars    # <-- the file you actually edit day to day
└── outputs.tf
```

---

## 0. One-time setup

```bash
terraform init
```

Only needed once per machine (or after changing provider versions).

---

## 1. What's in `terraform.tfvars` and what each thing does

```hcl
region      = "us-west-2"
name_prefix = "dev"                    # prefixes every resource name, e.g. dev-ssm-role

tags = {
  Environment = "dev"
  ManagedBy   = "terraform"
}

create_reports_bucket = true            # see Scenario B below
reports_bucket_name   = "your-globally-unique-name"

enable_reporting_lambda = true          # see Scenario D below

patch_operations = {                    # see Scenario C below
  linux   = "Scan"
  windows = "Scan"
}
```

Everything else - documents, associations, inventory, and each OS's patch
approval rules - lives in the YAML files under `config/ssmconfig/dev/`
(see `exampleconfig.md` there), not here.

---

## Scenario A - "Just patch my Windows/Linux fleet normally, no custom rules"

This is the default. Nothing to change.

1. In `config/ssmconfig/dev/windows-custom.yaml` (or `linux-custom.yaml`),
   leave `create_custom_patch_baseline: false`. This means: use AWS's own
   built-in default baseline for that OS - no approval rules to write.
2. Make sure your instances are tagged:
   - `"Patch Group" = dev-windows-patch-group` (this is the tag AWS
     actually uses to pick the baseline)
   - whatever tags `patch_targets` in that same file expects (e.g.
     `Environment = dev`)
3. `terraform apply`.
4. Patching happens automatically on the schedule in
   `maintenance_window_schedule` (default: Sunday). To test without
   waiting a week, see `validate-ssm-module.ps1`.

## Scenario B - "I need my own custom patch policy instead of AWS's default"

1. Open the relevant `<os>-custom.yaml` file.
2. Set `create_custom_patch_baseline: true`.
3. Fill in `patch_approval_rules` (which patches auto-approve and how
   fast), `patch_approved_patches` / `patch_rejected_patches` if you need
   explicit allow/deny lists.
4. `terraform plan` - you should see a new `aws_ssm_patch_baseline`
   created for that OS, and its `patch_group` updated **in place** to
   point at your new baseline instead of AWS's default. Nothing else
   should move.
5. `terraform apply`.

Full field-by-field walkthrough: `config/ssmconfig/dev/exampleconfig.md`.

## Scenario C - "Test without actually installing anything (Scan only)"

Set in `terraform.tfvars`:

```hcl
patch_operations = {
  linux   = "Scan"
  windows = "Scan"
}
```

`Scan` reports compliance only - nothing gets installed or rebooted. Any
OS you don't list here just uses whatever `patch_operation` is set to in
its own YAML file (default `Install`). Flip to `Install` here once you
trust what Scan reported.

## Scenario D - "Do I need to create the S3 bucket myself?"

No - controlled by one flag:

- `create_reports_bucket = true` (default) → Terraform creates the bucket
  for you (encrypted, versioned, public access blocked). You just need to
  give it a name in `reports_bucket_name` that's lowercase and globally
  unique across all of AWS, not just your account - e.g.
  `myorg-ssm-reports-dev-uswest2`.
- `create_reports_bucket = false` → Terraform creates nothing and assumes
  a bucket with that name already exists (e.g. owned by another team).

This same bucket is where associations, inventory, patch-run logs, and the
Lambda's CSV reports all get written (different folders inside it -
`associations/`, `inventory/`, `patch-runs/`, `Reports/`).

## Scenario E - "Turn the compliance-report Lambda on/off"

One flag in `terraform.tfvars`:

```hcl
enable_reporting_lambda = true   # or false
```

- `true` → creates the Lambda function, its IAM role, and both triggers
  (a daily schedule + right after any patch run finishes). It writes a
  CSV (who's compliant, who isn't, and why) to `Reports/` in the same
  bucket.
- `false` → none of that gets created. You still get documents,
  associations, inventory, and patching - just no automated report.

You can flip this on later without affecting anything else - `plan` will
show only the Lambda-related resources changing.

---

## How the code flow actually works (plain language)

1. **You edit YAML**, not `.tf` files, for day-to-day policy changes:
   - `dev.yaml` - documents, associations, inventory, feature on/off
     switches
   - `linux-custom.yaml` / `windows-custom.yaml` - per-OS patch policy
2. **`main.tf` reads those YAML files** into Terraform values
   (`yamldecode`) the moment you run `plan` or `apply`. It also
   auto-discovers any file ending in `-custom.yaml` in that folder and
   turns the filename into an OS key - so a brand-new `rhel-custom.yaml`
   just works, no code change.
3. **`main.tf` calls the module** (`../../../module/ssm-module`),
   handing it: the YAML-derived policy, plus a handful of
   account-specific values from `terraform.tfvars` (bucket name, whether
   to create it, whether the Lambda exists, Scan/Install overrides).
4. **The module creates AWS resources** based on what you enabled:
   documents → associations → inventory → one patch baseline/patch
   group/maintenance window per OS → (optionally) the reporting Lambda +
   its triggers.
5. **AWS does the actual work on its own schedule** - associations run
   on their `schedule_expression`, patching runs on the maintenance
   window's cron, inventory refreshes daily, and (if enabled) the Lambda
   writes a CSV either daily or right after a patch run.
6. **You never see compliance data by creating something** - Patch/
   Association/Inventory compliance are AWS's own reporting on things
   that already ran, not resources you create directly.

---

## Common commands

```bash
terraform plan            # see what would change before applying
terraform apply           # actually create/update AWS resources
terraform output          # see bucket name, patch baseline IDs, association IDs, etc.
```

To test end-to-end against a real instance without waiting for the
weekly schedule, see `create-test-instance.ps1` and
`validate-ssm-module.ps1`.

# terraform-waf

Enterprise, YAML-driven Terraform for AWS WAFv2 — one reusable module,
deployed independently into two regions from the same config-driven pattern.

```
terraform-waf/
├── module/
│   └── waf-module/               # CHILD module - generic, reusable, no YAML knowledge
│       ├── main.tf                # terraform/provider requirements
│       ├── variables.tf            # every input, validated
│       ├── locals.tf                # merges all rule sources into one list
│       ├── web-acl.tf                # THE aws_wafv2_web_acl resource + geo rules
│       ├── managed-rules.tf           # normalizes AWS managed rule groups
│       ├── custom-rules.tf             # normalizes byte/size/sqli/xss rules
│       ├── rate-limit.tf                # normalizes rate-based rules
│       ├── ip-set.tf                     # aws_wafv2_ip_set + normalized entries
│       ├── regex-pattern.tf               # aws_wafv2_regex_pattern_set + entries
│       ├── logging.tf                      # aws_wafv2_web_acl_logging_configuration
│       ├── association.tf                  # aws_wafv2_web_acl_association
│       └── outputs.tf
│
├── config/
│   └── wafconfig/
│       └── webacls/
│           └── dev.yaml          # ONE shared security policy for all dev deployments
│
└── deployment/
    └── dev/
        ├── us-west-2/            # ROOT module for this account+region+env
        │   ├── provider.tf         # aws provider + default_tags (LOCAL state for now - see note below)
        │   ├── main.tf              # yamldecode(...) + module "waf" { source = "../../../module/waf-module" }
        │   ├── variables.tf          # aws_region, default_tags, webacl_config_file, scope, resource_arns, log_destination_configs
        │   ├── terraform.tfvars       # points at dev.yaml + this region's scope/ARNs/log destination
        │   └── outputs.tf              # module.waf.* passthrough
        │
        └── us-east-1/             # Same root module shape, same dev.yaml, different region + scope
            ├── provider.tf
            ├── main.tf
            ├── variables.tf
            ├── terraform.tfvars     # points at the SAME dev.yaml + CLOUDFRONT scope
            └── outputs.tf
```

## State: currently local, S3 backend coming later

Both `deployment/dev/*` folders intentionally have **no `backend.tf`** right
now — Terraform stores state in a local `terraform.tfstate` file in each
folder instead of S3. This was pulled out on purpose to unblock work while
the real S3 bucket/backend setup is finalized.

When that's ready, add a `backend.tf` back into each folder:

```hcl
terraform {
  backend "s3" {
    # left blank - supply real values via: terraform init -backend-config=backend.hcl
  }
}
```

along with a `backend.hcl` per region (bucket, key, region, and either
`use_lockfile = true` for native S3 locking on Terraform 1.10+, or a
`dynamodb_table` for older versions) — then run
`terraform init -backend-config=backend.hcl -migrate-state` to move the
existing local state into S3 without losing it.

## One module, two regions, two scopes

Both `deployment/dev/us-west-2` and `deployment/dev/us-east-1` call the
exact same `module/waf-module` — nothing in the module changes between
regions. What differs is only the provider region (`terraform.tfvars`:
`aws_region`) and a few deployment-specific variables (below).

## One shared config, not one per region

`config/wafconfig/webacls/dev.yaml` is loaded by **every** dev deployment,
regardless of region or scope. It holds only what's genuinely shared
security policy: managed rule groups, rate limits, IP sets, regex rules,
custom rules, tags, default action, logging toggle/redaction. None of that
needs to differ between `us-west-2` and `us-east-1`, so it isn't duplicated.

What's deliberately **not** in the YAML — because it's inherently
region/scope-specific — is supplied as plain Terraform variables in each
deployment's own `terraform.tfvars` instead:

| Variable | Why it can't be shared |
|---|---|
| `scope` | `REGIONAL` vs `CLOUDFRONT` is a per-deployment AWS constraint |
| `resource_arns` | The ALB/API GW/AppSync resource being protected lives in one region |
| `log_destination_configs` | Firehose/CloudWatch/S3 log destinations are region-scoped ARNs |

`main.tf` in each deployment loads the shared YAML for everything else, then
passes `var.scope`, `var.resource_arns`, and `var.log_destination_configs`
straight into `module.waf`:

```hcl
module "waf" {
  source = "../../../module/waf-module"

  name                = local.waf_config.name
  managed_rule_groups = try(local.waf_config.managed_rule_groups, [])
  # ...rest of the shared policy from YAML...

  scope                   = var.scope                    # from tfvars
  resource_arns           = var.resource_arns              # from tfvars
  log_destination_configs = var.log_destination_configs     # from tfvars
}
```

If a new environment needs genuinely different rules (not just a different
region), that's when a second YAML file is warranted — e.g.
`config/wafconfig/webacls/prod.yaml`. Same region/scope doesn't need one.

## How the child module is organized internally

AWS WAFv2 requires all rules to live inside a single `aws_wafv2_web_acl`
resource's `rule` blocks — there's no separate "rule" resource type. To
still keep each rule category in its own file:

1. `managed-rules.tf`, `rate-limit.tf`, `ip-set.tf`, `regex-pattern.tf`,
   `custom-rules.tf`, and the geo-match block in `web-acl.tf` each build a
   `local` list of rule objects in a common shape:
   `{ rule_type, name, priority, action/override_action, <type-specific data> }`.
2. `locals.tf` concatenates them into `local.all_rules`.
3. `web-acl.tf` has **one** `dynamic "rule"` block that iterates
   `local.all_rules` and branches on `rule.value.rule_type` to render the
   correct `action`/`override_action` and `statement` shape.

`ip-set.tf` and `regex-pattern.tf` also own real standalone AWS resources
(`aws_wafv2_ip_set`, `aws_wafv2_regex_pattern_set`) since those exist
independently of the Web ACL.

## Custom rules: single-statement vs compound (AND/OR/NOT)

`custom_rules` in YAML supports one statement per rule (`byte_match`,
`size_constraint`, `sqli_match`, `xss_match`) against one field — covers most
custom WAF needs. Compound logic (e.g. "block if URI contains X **and**
method is POST") is a documented extension point at the top of
`module/waf-module/custom-rules.tf`, deliberately not built until a concrete
case needs it.

## Usage (local state, current setup)

```bash
# us-west-2 (REGIONAL)
cd deployment/dev/us-west-2
terraform init
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars

# us-east-1 (CLOUDFRONT)
cd deployment/dev/us-east-1
terraform init
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Service-agnostic associations

`resource_arns` in a `REGIONAL` YAML config accepts any WAFv2-associable
resource — ALB, API Gateway REST API stage, AppSync GraphQL API, Cognito
user pool, Verified Access instance — or can be left empty and attached
later. The module places no assumption on which service it's protecting.

## Staged rollout of managed rule groups

Set `override_action: count` on a managed rule group in the YAML to run it
in monitor-only mode first, watch CloudWatch metrics/logs, then flip to
`none` once confident — a one-line YAML change, no HCL edits.

## Priority convention

All rule types share one priority space in the Web ACL. This example uses:
- `5–9`: IP allow-lists (evaluate first so trusted traffic is never blocked later)
- `10–49`: AWS managed rule groups
- `50–59`: regex-pattern rules
- `60–69`: custom rules
- `100+`: rate-based rules

Adjust per your own risk model, just keep every priority in a given YAML file unique.

## Outputs

| Name | Description |
|---|---|
| `web_acl_id` / `web_acl_arn` / `web_acl_name` | Core Web ACL identifiers |
| `web_acl_capacity` | Consumed WCU, track as you add rules (default cap 1,500) |
| `ip_set_ids` / `ip_set_arns` | Map of IP set name → ID/ARN |
| `regex_pattern_set_ids` / `regex_pattern_set_arns` | Map of regex set name → ID/ARN |
| `association_ids` | Map of resource ARN → association ID (REGIONAL only) |
| `logging_configuration_id` | Logging config ID, if enabled |

# guardduty-module

Standalone, reusable Terraform for AWS GuardDuty. Same architecture as
`waf-module`: a generic child module, shared YAML policies, and one
deployment file that handles every role via toggle flags.

- **New operation you need?** → [`docs/CONFIG_EXAMPLES.md`](./docs/CONFIG_EXAMPLES.md)
- **Where is this headed?** → [`ROADMAP.md`](./ROADMAP.md)

```
guardduty-module/
├── module/
│   └── guardduty-module/          # CHILD module - generic, reusable, no YAML knowledge
│       ├── main.tf                  # terraform/provider requirements
│       ├── variables.tf              # every input, validated
│       ├── detector.tf                # aws_guardduty_detector (conditional - see create_detector)
│       ├── features.tf                 # aws_guardduty_detector_feature (S3/EKS/Malware/etc.)
│       ├── ip-set.tf                    # aws_guardduty_ipset (trusted IPs)
│       ├── threat-intel-set.tf           # aws_guardduty_threatintelset (known-bad IPs)
│       ├── filter.tf                      # aws_guardduty_filter (suppress/archive findings)
│       ├── publishing.tf                   # aws_guardduty_publishing_destination
│       ├── organization.tf                  # multi-account: admin designation, org config, members
│       └── outputs.tf
│
├── config/
│   └── guarddutyconfig/
│       └── detectors/
│           ├── dev.yaml            # single-account policy (Role 1 example)
│           ├── prod.yaml            # single-account policy (Role 1, second example - proves "just add a file")
│           ├── org-management.yaml   # Role 2: one-time bootstrap (optional)
│           └── audit-account.yaml     # Role 3: centralizes every account's findings (optional)
│
├── deployment/
│   └── us-west-2/                 # ONE deployment file, THREE roles toggled by flags
│       ├── provider.tf
│       ├── main.tf                  # three conditional `module` blocks, one per role
│       ├── variables.tf              # enable_single_account / enable_org_management / enable_audit_account
│       ├── terraform.tfvars           # flip exactly ONE role's flag per apply
│       └── outputs.tf
│
├── docs/
│   └── CONFIG_EXAMPLES.md
├── ROADMAP.md
└── README.md
```

## Three roles - but Role 1 is the one almost everyone uses

| Role | Flag | What it's for | Do you need it? |
|---|---|---|---|
| **1. Single account** | `enable_single_account` | A plain detector for one account - dev, prod, staging, anything | **Yes, almost always.** This is the default case. |
| **2. Org-management bootstrap** | `enable_org_management` | One-time: designates which account is allowed to administer GuardDuty org-wide | **Only if you need Role 3.** Skip entirely otherwise. |
| **3. Audit account** | `enable_audit_account` | Centralizes every org member account's findings into one detector + one S3 export | **Only if you have many accounts and want one place to see/export all their findings.** |

If you only ever run GuardDuty per-account with no centralized view, you
**never touch Roles 2 or 3** — just use Role 1 everywhere, once per account.

## Role 1: onboarding a new account (dev, prod, staging, ...)

No `.tf` code changes, ever. Just:

1. Copy `config/guarddutyconfig/detectors/dev.yaml` to a new file, e.g.
   `prod.yaml` (already included as a worked example - compare it to
   `dev.yaml` to see what changed: faster finding frequency, no
   auto-archive filters, prod's own tags).
2. In that account's `terraform.tfvars`:
   ```hcl
   enable_single_account      = true
   single_account_config_file = "prod.yaml"
   ```
3. Apply, using that account's own AWS credentials.

Every account is fully independent — no shared state, no dependency on
Roles 2/3 existing at all.

## Roles 2 & 3: centralizing findings across many accounts (e.g. all 100)

This is opt-in and only relevant once you want one place to see (and export
to S3) every account's findings instead of each account managing its own.

**The only real precondition**: some account must already be designated as
the GuardDuty delegated admin. That designation can come from **anywhere**
— the AWS console, the CLI, someone else's Terraform, or our own
`org-management` role below. Our code has **no dependency on which of
those happened** — `enable_audit_account` doesn't take an ARN or reference
`org-management` in any way. `aws_guardduty_organization_configuration`
only needs the audit account's own `detector_id`; AWS validates delegation
based on which account you're authenticated as when you apply, not on
anything passed in Terraform config.

**If delegation already exists** (however it happened), skip straight to:
```hcl
enable_audit_account = true
auto_enable_organization_members = "ALL"  # pulls in every EXISTING account, not just future ones
enable_publishing = true
publishing_destination_arn = "arn:aws:s3:::your-central-findings-bucket"
```
applied with the audit account's own credentials. Nothing else needed.

**If delegation does NOT exist yet** and you want Terraform to do that
one-time grant too, apply `org-management.yaml`'s role first (once), using
the AWS Organizations **management account's own credentials**:
```hcl
enable_org_management = true
```
This just tells AWS which account is allowed to administer GuardDuty for
the org — a one-time bootstrap, not something you keep re-applying, and not
something `enable_audit_account` reads from or depends on at the code
level. Once it's done (by any means), Role 3 above works on its own.

**Why two accounts (management + audit) instead of one?** AWS restricts
who can *designate* the admin (management account only), but AWS's own
guidance recommends the admin role itself live in a separate dedicated
account rather than the management account — keeping billing/org-root
control separate from security tooling. If that separation doesn't matter
for your org, you could point `delegated_admin_account_id` at the
management account itself and skip having a distinct audit account — but
the safer, AWS-recommended default is a separate account, which is what's
set up here.

## One file, three roles — still different AWS accounts

Combining these into one `main.tf` (via `count = var.enable_<role> ? 1 : 0`
on each `module` block) is a file-organization convenience only — **it does
not collapse the underlying AWS accounts into one.** You still switch AWS
credentials per account and set only that role's flag `true` for the
account you're currently targeting. Setting `enable_org_management = true`
while authenticated as the wrong account doesn't just misconfigure
something — AWS's API itself rejects that specific call from any account
except the real management account.

## Usage

```bash
cd deployment/us-west-2
terraform init
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Filters vs. suppression — a note on false positives

`filters` with `action: ARCHIVE` auto-archives matching findings entirely —
useful once you're confident a pattern is expected noise. Start new filters
with `action: NOOP` instead (matches without archiving) so you can confirm
what a filter *would* catch before committing to silencing it.

## Findings bucket: same account, or a different account entirely

`enable_publishing = true` needs a destination bucket. Three options,
handled differently because this module can only ever create resources in
the account it's applied against:

| Scenario | How |
|---|---|
| Let the module create its own bucket (recommended) | `create_publishing_bucket = true` + `publishing_bucket_name` — bucket, encryption, versioning, and policy all handled automatically, same account as the detector |
| Existing bucket, same account | `publishing_destination_arn` pointing at it — you attach the policy yourself (see `external_bucket_policy_json` output for the exact statement) |
| Existing bucket, **different** account | Same as above, but that account's owner has to apply the policy — this module has no credentials to reach into another account. Run `terraform output -raw external_bucket_policy_json` and hand it over. |

GuardDuty requires the destination bucket to use **SSE-KMS specifically**
— `publishing_kms_key_arn` is effectively required whenever
`enable_publishing = true`; the module fails fast with a clear message if
it's missing rather than letting AWS's API error surface later.

## Testing

GuardDuty is passive detection, not a firewall — `terraform apply`
succeeding only proves the detector is configured, not that detection
works. Use AWS's built-in sample findings to verify end-to-end without
real risk:

```bash
DETECTOR_ID=$(terraform output -raw account_detector_id)
aws guardduty create-sample-findings --detector-id "$DETECTOR_ID" \
  --finding-types "Recon:EC2/PortProbeUnprotectedPort"
```

Then check **GuardDuty → Findings** in the console (correct region) for a
finding tagged `[SAMPLE]`.

## Outputs

Each output is `null` unless the matching `enable_*` flag was `true` for
that apply.

| Name | Populated when |
|---|---|
| `account_detector_id` / `account_filter_ids` | `enable_single_account = true` |
| `org_management_admin_designated` | `enable_org_management = true` |
| `audit_account_detector_id` / `audit_account_member_account_ids` | `enable_audit_account = true` |

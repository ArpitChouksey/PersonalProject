# GuardDuty Config Examples

Copy-paste snippets for common operations. Drop these into
`config/guarddutyconfig/detectors/dev.yaml` (or a new environment's YAML).

---

## 1. Enable a specific protection feature

```yaml
features:
  - name: EKS_RUNTIME_MONITORING
    status: ENABLED
    additional_configuration:
      - name: EKS_ADDON_MANAGEMENT
        status: ENABLED
```

## 2. Trust a known-safe IP range (never alert on it)

```yaml
ip_sets:
  - name: CorpVpnRange
    format: TXT               # a plain-text file, one CIDR per line, hosted at `location`
    location: "https://s3.amazonaws.com/my-bucket/corp-vpn-ips.txt"
    activate: true
```

## 3. Add a known-malicious IP feed (always alert on it)

```yaml
threat_intel_sets:
  - name: ThirdPartyThreatFeed
    format: STIX
    location: "https://s3.amazonaws.com/my-bucket/threat-feed.stix"
    activate: true
```

## 4. Suppress (auto-archive) a specific noisy finding type

```yaml
filters:
  - name: ArchiveExpectedPortScans
    description: "Internal vulnerability scanner triggers this - expected"
    action: ARCHIVE
    rank: 2
    criteria:
      - field: type
        equals: ["Recon:EC2/PortProbeUnprotectedPort"]
      - field: resource.instanceDetails.tags.value
        equals: ["vuln-scanner"]
```

## 5. Only flag high-severity findings from a specific finding type (match, don't archive)

```yaml
filters:
  - name: HighSeverityCryptoMining
    description: "Track but don't auto-archive - route to alerting instead"
    action: NOOP
    rank: 3
    criteria:
      - field: type
        equals: ["CryptoCurrency:EC2/BitcoinTool.B!DNS"]
      - field: severity
        greater_than_or_equal: "7"
```

## 6. Publish findings to S3 (done via terraform.tfvars, not YAML)

```hcl
# deployment/us-west-2/terraform.tfvars
enable_publishing          = true
publishing_destination_arn = "arn:aws:s3:::my-guardduty-findings-bucket"
publishing_kms_key_arn     = "arn:aws:kms:us-west-2:111122223333:key/abcd-1234"
```

This is region-specific (like `waf-module`'s `log_destination_configs`), so
it lives in `terraform.tfvars`, not the shared YAML.

## After editing any config

```bash
cd deployment/us-west-2
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

---

## Multi-account (AWS Organizations)

### 7. Designate a delegated admin account (apply from the management account only)

```yaml
# config/guarddutyconfig/detectors/org-management.yaml
create_detector: false
enable_organization_admin: true
delegated_admin_account_id: "222233334444"
```

```bash
cd deployment/us-west-2
# in terraform.tfvars: enable_org_management = true, enable_single_account = false, enable_audit_account = false
terraform apply -var-file=terraform.tfvars   # must use MANAGEMENT ACCOUNT credentials
```

### 8. Configure the delegated admin's own detector + org-wide auto-enrollment (apply from the security/audit account, after #7)

```yaml
# config/guarddutyconfig/detectors/audit-account.yaml
is_organization_admin: true
auto_enable_organization_members: NEW    # or ALL / NONE
organization_features:
  - name: S3_DATA_EVENTS
    auto_enable: NEW
```

```bash
cd deployment/us-west-2
# in terraform.tfvars: enable_audit_account = true, enable_single_account = false, enable_org_management = false
terraform apply -var-file=terraform.tfvars   # must use the DELEGATED ADMIN ACCOUNT's own credentials
```

### 9. Explicitly invite specific accounts instead of auto-enrolling everyone

```yaml
auto_enable_organization_members: NONE

member_accounts:
  - account_id: "333344445555"
    email: "aws-account-333@example.com"
  - account_id: "444455556666"
    email: "aws-account-444@example.com"
```

---

## Findings bucket ownership

### 10. Self-created bucket, same account as the detector (recommended)

```hcl
# terraform.tfvars
enable_publishing         = true
create_publishing_bucket  = true
publishing_bucket_name    = "my-org-guardduty-findings-222233334444"   # must be globally unique
publishing_kms_key_arn    = "arn:aws:kms:us-west-2:222233334444:key/abcd-1234"
```

The module creates the bucket, blocks public access, enables versioning,
and attaches the correct bucket policy automatically. `publishing_destination_arn`
is ignored in this mode.

### 11. Existing bucket in the SAME account

```hcl
enable_publishing          = true
create_publishing_bucket   = false
publishing_destination_arn = "arn:aws:s3:::my-existing-bucket"
publishing_kms_key_arn     = "arn:aws:kms:us-west-2:222233334444:key/abcd-1234"
```

You're responsible for that bucket already having a policy allowing
`guardduty.amazonaws.com` to write to it (see the `external_bucket_policy_json`
output for the exact statement needed, even for a same-account bucket).

### 12. Existing bucket in a DIFFERENT account

```hcl
enable_publishing          = true
create_publishing_bucket   = false
publishing_destination_arn = "arn:aws:s3:::bucket-owned-by-another-account"
publishing_kms_key_arn     = "arn:aws:kms:us-west-2:222233334444:key/abcd-1234"
```

Then:
```bash
terraform apply -var-file=terraform.tfvars
terraform output -raw external_bucket_policy_json
```
Copy that output and hand it to whoever manages the bucket-owning account's
Terraform (or console) — **this module cannot apply it there itself**,
since it has no credentials for that other account. That account's KMS key
policy (if not the default) also needs to grant GuardDuty
`kms:GenerateDataKey` + `kms:Decrypt` — not generated by this output, since
key policy details vary.

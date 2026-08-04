# Roadmap

## Phase 0 — Module foundation ✅ done

- `module/guardduty-module/` — detector, optional features, IP sets, threat
  intel sets, filters, publishing destination, multi-account organization
  support (all opt-in via variables)
- `config/guarddutyconfig/detectors/`: `dev.yaml` + `prod.yaml` (Role 1
  single-account examples), `org-management.yaml` + `audit-account.yaml`
  (Roles 2/3, optional multi-account)
- `deployment/us-west-2/` — one deployment file, all three roles toggled by
  flags, local state

## Phase 1 — Tune filters against real findings

- [ ] Enable GuardDuty in dev with default features, let it run for a
      baseline period (1–2 weeks) with no filters
- [ ] Review findings in the console, identify expected/noisy patterns
      (internal scanners, known test traffic, etc.)
- [ ] Add `filters` entries to archive confirmed-safe noise; use `NOOP`
      first if unsure whether a finding type should be archived, so you can
      watch what it would have archived before committing to it

## Phase 2 — Roll out remaining protection features

- [ ] Confirm which features are already active by default vs. need
      explicit enabling (AWS periodically adds new ones)
- [ ] Enable `EKS_RUNTIME_MONITORING` if running EKS, with
      `EKS_ADDON_MANAGEMENT` sub-feature
- [ ] Enable `RUNTIME_MONITORING` for EC2/Fargate if using those workloads

## Phase 3 — Findings export & alerting

- [ ] Set `enable_publishing = true` with a real S3 bucket + KMS key ARN in
      `terraform.tfvars`
- [ ] Wire findings into existing SIEM/alerting (EventBridge rule on
      GuardDuty findings is the common pattern - not yet in this module)
- [ ] Alarm on new HIGH/CRITICAL severity findings

## Phase 4 — Multi-region / multi-account

- [ ] Add a second region deployment (same pattern as `waf-module`'s
      us-west-2/us-east-1 split) if workloads run in more than one region
- [x] Multi-account support built: `enable_organization_admin` (management
      account), `is_organization_admin` + `auto_enable_organization_members`
      + `organization_features` + `member_accounts` (delegated admin
      account) — see `deployment/us-west-2/terraform.tfvars`'s
      `enable_org_management` / `enable_audit_account` flags
- [ ] Apply `org-management.yaml` from the real management account, then
      `audit-account.yaml` from the real designated security account, in
      that order, and confirm in the console that the admin designation
      took effect before configuring org-wide settings
- [ ] Decide on `auto_enable_organization_members`: `ALL` retroactively
      enrolls every existing member account - confirm that's desired
      before applying (vs. `NEW`, which only affects future accounts)

## Phase 5 — Production hardening

- [ ] Add a real S3 backend (see `waf-module`'s README for the same pattern)
- [ ] Periodic review of IP sets / threat intel sets for staleness

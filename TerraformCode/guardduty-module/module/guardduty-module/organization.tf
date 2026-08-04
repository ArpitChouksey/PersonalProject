##############################################
# MULTI-ACCOUNT (AWS ORGANIZATIONS) - all optional, opt-in
#
# A single-account deployment never creates any resource in this file -
# every one is gated behind a variable that defaults to false/empty.
##############################################

# ---------------------------------------------------------------------------
# Run ONLY from the ORGANIZATION MANAGEMENT ACCOUNT. Designates which
# account is the GuardDuty delegated administrator for the whole org. Does
# NOT require a detector in the management account itself - this is why
# create_detector exists as a separate switch.
# ---------------------------------------------------------------------------
resource "aws_guardduty_organization_admin_account" "this" {
  count = var.enable_organization_admin ? 1 : 0

  admin_account_id = var.delegated_admin_account_id
}

# ---------------------------------------------------------------------------
# Run from the DELEGATED ADMIN ACCOUNT ITSELF, after the management account
# has already applied enable_organization_admin above. Controls whether new
# or existing org member accounts get auto-enrolled into GuardDuty.
# ---------------------------------------------------------------------------
resource "aws_guardduty_organization_configuration" "this" {
  count = var.is_organization_admin ? 1 : 0

  detector_id                      = local.detector_id
  auto_enable_organization_members = var.auto_enable_organization_members
}

# ---------------------------------------------------------------------------
# Org-wide feature auto-enablement (e.g. auto-enable EKS Runtime Monitoring
# for every member account, not just this one). Also delegated-admin-only.
# ---------------------------------------------------------------------------
resource "aws_guardduty_organization_configuration_feature" "this" {
  for_each = var.is_organization_admin ? { for f in var.organization_features : f.name => f } : {}

  detector_id = local.detector_id
  name        = each.value.name
  auto_enable = each.value.auto_enable

  dynamic "additional_configuration" {
    for_each = each.value.additional_configuration
    content {
      name        = additional_configuration.value.name
      auto_enable = additional_configuration.value.auto_enable
    }
  }
}

# ---------------------------------------------------------------------------
# Explicit member account association - needed when
# auto_enable_organization_members = NONE, or for accounts outside the
# organization (invited rather than auto-enrolled). Also delegated-admin-only.
# ---------------------------------------------------------------------------
resource "aws_guardduty_member" "this" {
  for_each = var.is_organization_admin ? { for m in var.member_accounts : m.account_id => m } : {}

  detector_id = local.detector_id
  account_id  = each.value.account_id
  email       = each.value.email
  invite      = true
}

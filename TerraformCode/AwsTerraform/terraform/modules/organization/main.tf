data "aws_organizations_organization" "current" {}

resource "aws_organizations_organization" "this" {
  feature_set = "ALL"

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]

  lifecycle {
    ignore_changes = [
      aws_service_access_principals
    ]
  }
}

resource "aws_organizations_organizational_unit" "this" {
  for_each = var.organizational_units

  name      = each.value.name
  parent_id = each.value.parent_id != null ? each.value.parent_id : data.aws_organizations_organization.current.roots[0].id
}

resource "aws_organizations_account" "this" {
  for_each = var.accounts

  name      = each.value.name
  email     = each.value.email
  parent_id = each.value.parent_id

  close_on_deletion = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_policy" "this" {
  for_each = var.service_control_policies

  name        = each.value.name
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"

  content = each.value.content

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_policy_attachment" "this" {
  for_each = merge([
    for policy_key, policy in var.service_control_policies : {
      for target_id in policy.targets :
      "${policy_key}:${target_id}" => {
        policy_id = policy_key
        target_id = target_id
      }
    }
  ]...)

  policy_id = aws_organizations_policy.this[each.value.policy_id].id
  target_id = each.value.target_id
}

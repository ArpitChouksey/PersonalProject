resource "aws_organizations_organization" "this" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com"
  ]

  feature_set = "ALL"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "accounts" {
  for_each = var.accounts

  name      = each.value.name
  email     = each.value.email
  role_name = "OrganizationAccountAccessRole"

  tags = {
    Environment = "management"
    Project     = "terraform-multi-env"
    ManagedBy   = "terraform"
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      role_name,
      iam_user_access_to_billing
    ]
  }
}

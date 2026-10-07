data "aws_ssoadmin_instances" "this" {}

locals {
  instance_arn = data.aws_ssoadmin_instances.this.arns[0]
}

resource "aws_ssoadmin_permission_set" "this" {
  for_each = var.permission_sets

  instance_arn = local.instance_arn

  name             = each.value.name
  description      = each.value.description
  session_duration = each.value.session_duration

  tags = each.value.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_identitystore_user" "this" {
  for_each = var.users

  identity_store_id = var.identity_store_id

  display_name = each.value.display_name
  user_name    = each.value.user_name

  name {
    given_name  = each.value.given_name
    family_name = each.value.family_name
  }

  emails {
    value   = each.value.email
    type    = "work"
    primary = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = var.account_assignments

  instance_arn = local.instance_arn

  permission_set_arn = aws_ssoadmin_permission_set.this[
    each.value.permission_set_key
  ].arn

  principal_id = aws_identitystore_user.this[
    each.value.user_key
  ].user_id

  principal_type = "USER"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}

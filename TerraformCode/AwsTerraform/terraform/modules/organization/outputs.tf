output "organization_id" {
  value = data.aws_organizations_organization.current.id
}

output "root_id" {
  value = data.aws_organizations_organization.current.roots[0].id
}

output "organizational_units" {
  value = {
    for key, ou in aws_organizations_organizational_unit.this :
    key => ou.id
  }
}

output "accounts" {
  value = {
    for key, account in aws_organizations_account.this :
    key => account.id
  }
}

output "policies" {
  value = {
    for key, policy in aws_organizations_policy.this :
    key => policy.id
  }
}

output "organization_id" {
  value = aws_organizations_organization.this.id
}

output "accounts" {
  value = aws_organizations_account.accounts
}

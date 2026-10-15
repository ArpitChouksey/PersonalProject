output "security_group_ids" {
  value = {
    for key, sg in aws_security_group.this :
    key => sg.id
  }
}

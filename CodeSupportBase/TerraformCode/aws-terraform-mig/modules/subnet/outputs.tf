output "subnet_ids" {
  value = {
    for key, subnet in aws_subnet.this :
    key => subnet.id
  }
}

output "subnet_arns" {
  value = {
    for key, subnet in aws_subnet.this :
    key => subnet.arn
  }
}

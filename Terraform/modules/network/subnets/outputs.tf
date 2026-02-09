output "subnet_ids" {
  value = {
    for k, s in aws_subnet.this : k => s.id
  }
}

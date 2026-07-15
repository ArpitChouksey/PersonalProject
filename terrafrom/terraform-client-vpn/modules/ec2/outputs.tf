output "instance_id" {
  value = aws_instance.this.id
}

output "instance_arn" {
  value = aws_instance.this.arn
}

output "instance_name" {
  value = aws_instance.this.tags["Name"]
}

output "private_ip" {
  value = aws_instance.this.private_ip
}

output "private_dns" {
  value = aws_instance.this.private_dns
}

output "availability_zone" {
  value = aws_instance.this.availability_zone
}

output "security_groups" {
  value = aws_instance.this.vpc_security_group_ids
}

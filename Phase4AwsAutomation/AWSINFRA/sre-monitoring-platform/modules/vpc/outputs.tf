output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_a" {
  value = aws_subnet.public_a.id
}

output "public_subnet_b" {
  value = aws_subnet.public_b.id
}

output "private_subnet_a" {
  value = aws_subnet.private_a.id
}

output "private_subnet_b" {
  value = aws_subnet.private_b.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}

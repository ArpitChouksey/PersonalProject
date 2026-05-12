output "vpc_id" {
  value = aws_vpc.connectivity_vpc.id
}

output "public_subnet_az1_id" {
  value = aws_subnet.public_subnet_az1.id
}

output "public_subnet_az2_id" {
  value = aws_subnet.public_subnet_az2.id
}

output "private_subnet_az1_id" {
  value = aws_subnet.private_subnet_az1.id
}

output "private_subnet_az2_id" {
  value = aws_subnet.private_subnet_az2.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.connectivity_igw.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.connectivity_nat.id
}

output "bastion_public_ip" {
  value = aws_instance.bastion_host.public_ip
}

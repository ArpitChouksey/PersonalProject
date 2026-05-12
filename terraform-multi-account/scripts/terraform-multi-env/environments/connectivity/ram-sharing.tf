resource "aws_ram_resource_share" "shared_network" {
  name                      = "shared-network-subnets"
  allow_external_principals = true

  tags = {
    Name = "shared-network-subnets"
  }
}

resource "aws_ram_principal_association" "dev_account" {
  principal          = "119004746935"
  resource_share_arn = aws_ram_resource_share.shared_network.arn
}

resource "aws_ram_resource_association" "public_subnet_az1" {
  resource_arn       = aws_subnet.public_subnet_az1.arn
  resource_share_arn = aws_ram_resource_share.shared_network.arn
}

resource "aws_ram_resource_association" "public_subnet_az2" {
  resource_arn       = aws_subnet.public_subnet_az2.arn
  resource_share_arn = aws_ram_resource_share.shared_network.arn
}

resource "aws_ram_resource_association" "private_subnet_az1" {
  resource_arn       = aws_subnet.private_subnet_az1.arn
  resource_share_arn = aws_ram_resource_share.shared_network.arn
}

resource "aws_ram_resource_association" "private_subnet_az2" {
  resource_arn       = aws_subnet.private_subnet_az2.arn
  resource_share_arn = aws_ram_resource_share.shared_network.arn
}

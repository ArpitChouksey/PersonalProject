resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Bastion access security group"
  vpc_id      = aws_vpc.connectivity_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "bastion-sg"
    Environment = "connectivity"
  }

  #lifecycle {
  #  prevent_destroy = true
  #}
}

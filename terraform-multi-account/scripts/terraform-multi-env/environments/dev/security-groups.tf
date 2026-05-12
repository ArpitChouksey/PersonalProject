resource "aws_security_group" "dev_alb_sg" {
  name        = "dev-alb-sg"
  description = "Security group for public ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
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
    Name = "dev-alb-sg"
  }
}

resource "aws_security_group" "dev_private_ec2_sg" {
  name        = "dev-private-ec2-sg"
  description = "Private EC2 SG for shared VPC workloads"
  #description = "Private application EC2 SG"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.dev_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-private-ec2-sg"
  }
}

###############################################################
# EC2 + Public ALB -- for the "hit ALB and EC2" REST API test
#
# Deliberately internet-facing, reached via a plain `type: HTTP`
# integration (just a URL) instead of `type: ALB` through a VPC
# Link. VPC Links are the single slowest resource in this whole
# setup (5-15+ minutes) and add an NLB + security-group-in-VPC
# complexity that isn't needed just to prove "API Gateway can
# reach a load-balanced EC2 backend." If you specifically want to
# test the private VPC-Link path later, that's what the earlier,
# heavier prereqs module already covers.
###############################################################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "test_target" {

  name        = "${var.name_prefix}-test-target-sg"
  description = "Allows HTTP from the internet -- ALB is public-facing for this simplified test"
  vpc_id      = data.aws_vpc.default.id

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

}

resource "aws_instance" "test_target" {

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.test_target.id]

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "apigateway test target ok" > /usr/share/nginx/html/index.html
  EOF

  tags = {
    Name = "${var.name_prefix}-test-target"
  }

}

resource "aws_lb_target_group" "alb_target" {

  name     = "${var.name_prefix}-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path = "/"
  }

}

resource "aws_lb_target_group_attachment" "alb_target" {

  target_group_arn = aws_lb_target_group.alb_target.arn
  target_id        = aws_instance.test_target.id
  port             = 80

}

resource "aws_lb" "test_alb" {

  name               = "${var.name_prefix}-test-alb"
  internal           = false   # public-facing -- reachable via plain HTTP, no VPC Link
  load_balancer_type = "application"
  security_groups    = [aws_security_group.test_target.id]
  subnets            = data.aws_subnets.default.ids

}

resource "aws_lb_listener" "test_alb" {

  load_balancer_arn = aws_lb.test_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target.arn
  }

}

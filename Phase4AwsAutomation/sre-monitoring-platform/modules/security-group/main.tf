resource "aws_security_group" "platform" {

  name        = var.sg_name
  description = var.sg_description

  vpc_id = var.vpc_id

  dynamic "ingress" {

    for_each = var.allowed_ports

    content {

      from_port = ingress.value
      to_port   = ingress.value

      protocol = "tcp"

      cidr_blocks = [
        var.allowed_ip
      ]
    }
  }

  ingress {

    from_port = 80
    to_port   = 80

    protocol = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {

    from_port = 443
    to_port   = 443

    protocol = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {

    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = var.sg_name
  }
}

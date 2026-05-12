resource "aws_lb" "dev_shared_alb" {
  name               = "dev-shared-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.dev_alb_sg.id]

  subnets = [
    var.public_subnet_az1,
    var.public_subnet_az2
  ]

  enable_deletion_protection = false

  tags = {
    Name = "dev-shared-alb"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.dev_shared_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dev_nginx_tg.arn
  }
}

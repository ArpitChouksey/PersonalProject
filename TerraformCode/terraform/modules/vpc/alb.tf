################################
# APPLICATION LOAD BALANCER
################################

resource "aws_lb" "alb" {
  name               = "proj-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_sg_id]

#  lifecycle {
#    prevent_destroy = true
#  }
}


################################
# TARGET GROUP (NO TARGETS)
################################

resource "aws_lb_target_group" "app" {
  name        = "proj-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  lambda_multi_value_headers_enabled = false
  proxy_protocol_v2                  = false

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200"
  }

  tags = {
    Name        = "proj-app-tg"
    Project     = "AWS-3Tier"
    Environment = "dev"
  }
}


################################
# HTTP LISTENER (ONLY HTTP)
################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = "arn:aws:elasticloadbalancing:eu-north-1:211811255273:loadbalancer/app/proj-alb/7ad611ec77590724"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = "arn:aws:elasticloadbalancing:eu-north-1:211811255273:targetgroup/proj-app-tg/26ddc4e3c02e1e5d"
        weight = 1
      }

      stickiness {
        enabled  = false
        duration = 3600
      }
    }
  }

#  lifecycle {
#    prevent_destroy = true
#
#    ignore_changes = [
#      default_action,   # ← THIS is the key
#      tags
#    ]
#  }
}


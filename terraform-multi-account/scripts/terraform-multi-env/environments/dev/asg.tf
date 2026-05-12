resource "aws_autoscaling_group" "dev_nginx_asg" {
  name = "dev-nginx-asg"

  desired_capacity = 2
  max_size         = 4
  min_size         = 2

  vpc_zone_identifier = [
    var.private_subnet_az1,
    var.private_subnet_az2
  ]

  target_group_arns = [
    aws_lb_target_group.dev_nginx_tg.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.dev_nginx_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "dev-nginx-instance"
    propagate_at_launch = true
  }
}

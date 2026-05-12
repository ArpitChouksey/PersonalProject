output "alb_dns_name" {
  value = aws_lb.dev_shared_alb.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.dev_nginx_tg.arn
}

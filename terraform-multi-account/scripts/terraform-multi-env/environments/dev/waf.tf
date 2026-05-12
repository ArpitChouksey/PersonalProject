#resource "aws_wafv2_web_acl" "dev_alb_waf" {
#  name  = "dev-alb-waf"
#  scope = "REGIONAL"

#  default_action {
#    allow {}
#  }

#  visibility_config {
#    cloudwatch_metrics_enabled = false
#    metric_name                = "devAlbWaf"
#    sampled_requests_enabled   = false
#  }
#}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {

  alarm_name          = "sre-monitor-server-high-cpu"
  comparison_operator = "GreaterThanThreshold"

  evaluation_periods  = 1
  datapoints_to_alarm = 1

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"

  statistic = "Average"
  period    = 300

  threshold = 80

  dimensions = {
    InstanceId = var.instance_id
  }

  alarm_actions = [
    var.sns_topic_arn
  ]

  treat_missing_data = "missing"
}

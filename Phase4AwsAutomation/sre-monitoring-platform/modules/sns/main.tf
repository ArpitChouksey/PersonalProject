resource "aws_sns_topic" "alerts" {

  name = var.topic_name
}

resource "aws_sns_topic_subscription" "email" {

  topic_arn = aws_sns_topic.alerts.arn

  protocol = "email"

  endpoint = var.email

  confirmation_timeout_in_minutes = 1

  endpoint_auto_confirms = false
}

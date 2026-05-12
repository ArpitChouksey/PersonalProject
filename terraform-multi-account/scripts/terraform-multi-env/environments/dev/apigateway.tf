resource "aws_apigatewayv2_api" "dev_api" {
  name          = "testapi"
  protocol_type = "HTTP"
}

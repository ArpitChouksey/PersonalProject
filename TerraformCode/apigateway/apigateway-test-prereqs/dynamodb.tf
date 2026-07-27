###############################################################
# DynamoDB -- for the "hit DynamoDB" REST API test
#
# Like S3, DynamoDB is not in AWS's HTTP-API quick-create
# integration_subtype list -- direct DynamoDB access without a
# Lambda in front only works via a REST API's non-proxy AWS
# integration (raw config.uri + VTL request template), the same
# pattern used for SQS/EventBridge in the main test files.
###############################################################

resource "aws_dynamodb_table" "test_table" {

  name         = "${var.name_prefix}-test-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

}

data "aws_iam_policy_document" "apigateway_assume_role" {

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }

}

resource "aws_iam_role" "apigw_dynamodb" {

  name               = "${var.name_prefix}-dynamodb"
  assume_role_policy = data.aws_iam_policy_document.apigateway_assume_role.json

}

resource "aws_iam_role_policy" "apigw_dynamodb" {

  name = "dynamodb-access"
  role = aws_iam_role.apigw_dynamodb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:Query"]
      Resource = aws_dynamodb_table.test_table.arn
    }]
  })

}

###############################################################
# S3 -- for the "hit S3" REST API test
#
# Same reasoning as DynamoDB above: no direct HTTP-API quick-
# create support, so this uses a REST API's non-proxy AWS
# integration with a raw config.uri.
###############################################################

resource "aws_s3_bucket" "uploads" {

  # Account ID suffix guarantees global uniqueness -- S3 bucket
  # names collide across every AWS account, not just yours.
  bucket = "${var.name_prefix}-uploads-${data.aws_caller_identity.current.account_id}"

}

resource "aws_s3_bucket_public_access_block" "uploads" {

  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}

resource "aws_iam_role" "apigw_s3" {

  name               = "${var.name_prefix}-s3"
  assume_role_policy = data.aws_iam_policy_document.apigateway_assume_role.json

}

resource "aws_iam_role_policy" "apigw_s3" {

  name = "s3-access"
  role = aws_iam_role.apigw_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:GetObject"]
      Resource = "${aws_s3_bucket.uploads.arn}/*"
    }]
  })

}

data "aws_caller_identity" "current" {}

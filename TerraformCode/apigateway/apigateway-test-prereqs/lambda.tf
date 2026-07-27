###############################################################
# Single Lambda -- reused for HTTP, WebSocket, REST, and swagger
# import tests. Uses a pre-built, committed zip rather than an
# archive_file data source -- if your pipeline runs plan/apply as
# separate jobs in separate containers, archive_file's local-disk
# write doesn't survive between them.
###############################################################

resource "aws_iam_role" "lambda_basic_execution" {

  name = "${var.name_prefix}-lambda-basic-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {

  role       = aws_iam_role.lambda_basic_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

}

resource "aws_lambda_function" "hello" {

  function_name = "${var.name_prefix}-hello"

  role = aws_iam_role.lambda_basic_execution.arn

  handler = "hello_lambda.handler"
  runtime = "python3.12"
  timeout = 10

  filename         = "${path.module}/lambda_src/hello_lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_src/hello_lambda.zip")

}

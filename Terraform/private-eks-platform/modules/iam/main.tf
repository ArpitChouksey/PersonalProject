resource "aws_iam_role" "secret_reader" {
  name = var.secret_reader_role_name

  description = var.secret_reader_role_description

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "pods.eks.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = var.secret_reader_role_name
    }
  )
}

resource "aws_iam_role_policy" "secret_reader" {
  name = var.secret_reader_policy_name
  role = aws_iam_role.secret_reader.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadApplicationSecret"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]

        Resource = var.secret_arn
      },
      {
        Sid    = "DecryptApplicationSecret"
        Effect = "Allow"

        Action = [
          "kms:Decrypt"
        ]

        Resource = var.kms_key_arn
      }
    ]
  })
}

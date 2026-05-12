resource "aws_iam_role" "terraform_execution_role" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::${var.management_account_id}:root"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = "terraform-multi-env"
    ManagedBy   = "terraform"
  }

  #lifecycle {
  #  prevent_destroy = true
  #}
}

resource "aws_iam_role_policy_attachment" "admin_attach" {
  role       = aws_iam_role.terraform_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

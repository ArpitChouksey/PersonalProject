resource "aws_iam_user" "this" {
  name = var.user_name

  tags = {
    Environment = var.environment
    Project     = "terraform-multi-env"
  }
}

resource "aws_iam_user_policy_attachment" "admin_attach" {
  user       = aws_iam_user.this.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

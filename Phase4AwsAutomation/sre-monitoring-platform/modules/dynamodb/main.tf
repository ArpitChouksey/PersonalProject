resource "aws_dynamodb_table" "terraform_lock" {

  name         = var.table_name
  billing_mode = var.billing_mode

  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = var.table_name
  }
}

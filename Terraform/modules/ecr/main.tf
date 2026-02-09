resource "aws_ecr_repository" "this" {
  name                 = "eks-app-repo"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "eks-app-repo"
  }
}


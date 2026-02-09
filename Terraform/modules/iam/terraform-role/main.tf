resource "aws_iam_role" "this" {
  name = "terraform-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attachments" {
for_each = toset([
  "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
  "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
  "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
  "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
])


 # for_each = toset([
 #   "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
 #   "arn:aws:iam::aws:policy/AmazonEKSFullAccess",
 #   "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
 # ])

  role       = aws_iam_role.this.name
  policy_arn = each.value
}


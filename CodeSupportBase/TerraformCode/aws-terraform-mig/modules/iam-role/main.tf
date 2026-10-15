# ============================================================
# IAM ROLE
# ============================================================

resource "aws_iam_role" "this" {
  name        = var.role_name
  description = var.role_description

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}


# ============================================================
# SSM
# ============================================================

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# ============================================================
# S3 POLICY
# ============================================================

resource "aws_iam_policy" "s3" {
  name = var.s3_policy_name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "MigrationBucketAccess"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]

        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })

  tags = var.tags
}


resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.s3.arn
}


# ============================================================
# SECRETS MANAGER POLICY
# ============================================================

resource "aws_iam_policy" "secrets_manager" {
  name = var.secrets_manager_policy_name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadMigrationApplicationSecret"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = var.secret_policy_resource
      }
    ]
  })

  tags = var.tags
}


resource "aws_iam_role_policy_attachment" "secrets_manager" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.secrets_manager.arn
}


# ============================================================
# INSTANCE PROFILE
# ============================================================

resource "aws_iam_instance_profile" "this" {
  name = var.instance_profile_name
  role = aws_iam_role.this.name

  tags = var.tags
}

###########################################
# EC2 Trust Policy
###########################################

data "aws_iam_policy_document" "assume_role" {

  statement {

    effect = "Allow"

    principals {

      type = "Service"

      identifiers = [
        "ec2.amazonaws.com"
      ]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

###########################################
# IAM Role
###########################################

resource "aws_iam_role" "this" {

  name = var.role_name

  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-ec2-role"
    }
  )
}

###########################################
# SSM Policy
###########################################

resource "aws_iam_role_policy_attachment" "ssm" {

  role = aws_iam_role.this.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

###########################################
# Instance Profile
###########################################

resource "aws_iam_instance_profile" "this" {

  name = var.instance_profile_name

  role = aws_iam_role.this.name

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-instance-profile"
    }
  )
}

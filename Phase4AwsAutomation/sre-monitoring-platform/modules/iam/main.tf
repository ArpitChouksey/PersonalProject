resource "aws_iam_role" "eks_cluster_role" {

  name = var.cluster_role_name

  description = "Allows the cluster Kubernetes control plane to manage AWS resources on your behalf."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "eks.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "eks_node_role" {

  name = var.node_role_name

  description = "Allows EC2 instances to call AWS services on your behalf."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = [
          "ec2.amazonaws.com",
          "eks.amazonaws.com"
        ]
      }

      Action = "sts:AssumeRole"
    }]
  })
}

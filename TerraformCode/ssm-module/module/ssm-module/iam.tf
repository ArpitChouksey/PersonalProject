# Instance-profile role: lets managed instances register with SSM and write
# association/inventory/patch output to the reports bucket this module owns.

resource "aws_iam_role" "ssm_role" {
  name = "${var.name_prefix}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Scoped to only this module's bucket - not a blanket S3 write policy.
resource "aws_iam_role_policy" "ssm_reports_write" {
  count = var.create_reports_bucket ? 1 : 0
  name  = "${var.name_prefix}-ssm-reports-write"
  role  = aws_iam_role.ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:PutObject", "s3:GetBucketLocation"]
      Resource = [
        local.reports_bucket_arn,
        "${local.reports_bucket_arn}/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.name_prefix}-ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

# Separate service role for the maintenance window task that runs patching -
# SSM's maintenance window service assumes this to invoke Run Command on your
# behalf. Kept distinct from the instance role on purpose (different trust
# principal).
resource "aws_iam_role" "mw_task_role" {
  count = var.enable_patch_compliance ? 1 : 0
  name  = "${var.name_prefix}-ssm-mw-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ssm.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "mw_task_role_policy" {
  count      = var.enable_patch_compliance ? 1 : 0
  role       = aws_iam_role.mw_task_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
}

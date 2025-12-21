resource "aws_instance" "app" {
  ami                    = var.app_ami_id
  instance_type          = var.app_instance_type
  subnet_id              = var.app_subnet_id
  vpc_security_group_ids = [var.app_sg_id]
  key_name               = var.key_name

  tags = {
    Name        = var.app_instance_name
    Project     = "AWS-3Tier"
    Environment = "dev"
  }

#  lifecycle {
#    prevent_destroy = true
#    ignore_changes = [
#      ami,
#      user_data,
#      tags
#    ]
#  }
}


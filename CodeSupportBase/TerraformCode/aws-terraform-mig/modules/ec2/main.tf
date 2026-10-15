resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile = var.iam_instance_profile

  associate_public_ip_address = var.associate_public_ip_address

  disable_api_stop        = var.disable_api_stop
  disable_api_termination = var.disable_api_termination

  user_data = var.user_data

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

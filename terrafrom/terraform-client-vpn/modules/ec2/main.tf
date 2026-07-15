resource "aws_instance" "this" {

  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id = var.subnet_id

  private_ip = var.private_ip

  key_name = var.key_name

  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile = var.iam_instance_profile

  associate_public_ip_address = var.associate_public_ip_address

  monitoring = var.monitoring

  disable_api_termination = var.disable_api_termination

  ebs_optimized = var.ebs_optimized

  user_data = var.user_data

  root_block_device {

    volume_size = var.root_volume_size

    volume_type = var.root_volume_type

    encrypted = var.encrypted

    delete_on_termination = var.delete_on_termination
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.instance_name}"
    }
  )
}

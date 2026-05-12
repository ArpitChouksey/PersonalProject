resource "aws_instance" "bastion_host" {
  ami                    = "ami-0a59ec92177ec3fad"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_az1.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = "connectivity-bastion-key"

  tags = {
    Name        = "bastion-host"
    Environment = "connectivity"
  }

  #lifecycle {
  #  prevent_destroy = true

   # ignore_changes = [
   #   associate_public_ip_address,
   #   ami,
   #   vpc_security_group_ids
   # ]
  #}
}

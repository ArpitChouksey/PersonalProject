##############################################
# Windows Security Group
##############################################

resource "aws_security_group" "windows" {

  name        = "${var.project_name}-${var.environment}-windows-sg"
  description = "Windows Security Group"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-windows-sg"
    }
  )
}

##############################################
# Linux Security Group
##############################################

resource "aws_security_group" "linux" {

  name        = "${var.project_name}-${var.environment}-linux-sg"
  description = "Linux Security Group"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-linux-sg"
    }
  )
}

##############################################
# Database Security Group
##############################################

resource "aws_security_group" "database" {

  name        = "${var.project_name}-${var.environment}-database-sg"
  description = "Database Security Group"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-database-sg"
    }
  )
}

##############################################
# Windows RDP
##############################################

resource "aws_vpc_security_group_ingress_rule" "windows_rdp" {

  security_group_id = aws_security_group.windows.id

  cidr_ipv4 = var.vpn_cidr

  from_port = 3389
  to_port   = 3389

  ip_protocol = "tcp"

  description = "RDP from VPN"
}

##############################################
# Linux SSH
##############################################

resource "aws_vpc_security_group_ingress_rule" "linux_ssh" {

  security_group_id = aws_security_group.linux.id

  cidr_ipv4 = var.vpn_cidr

  from_port = 22
  to_port   = 22

  ip_protocol = "tcp"

  description = "SSH from VPN"
}

##############################################
# Database Access
##############################################

resource "aws_vpc_security_group_ingress_rule" "database" {

  security_group_id = aws_security_group.database.id

  referenced_security_group_id = aws_security_group.linux.id

  from_port = var.database_port
  to_port   = var.database_port

  ip_protocol = "tcp"

  description = "Database Access from Linux"
}

##############################################
# Windows Egress
##############################################

resource "aws_vpc_security_group_egress_rule" "windows" {

  security_group_id = aws_security_group.windows.id

  cidr_ipv4 = "0.0.0.0/0"

  ip_protocol = "-1"
}

##############################################
# Linux Egress
##############################################

resource "aws_vpc_security_group_egress_rule" "linux" {

  security_group_id = aws_security_group.linux.id

  cidr_ipv4 = "0.0.0.0/0"

  ip_protocol = "-1"
}

##############################################
# Database Egress
##############################################

resource "aws_vpc_security_group_egress_rule" "database" {

  security_group_id = aws_security_group.database.id

  cidr_ipv4 = "0.0.0.0/0"

  ip_protocol = "-1"
}

####################################
# AWS
####################################

aws_region = "us-east-1"

####################################
# Project
####################################

project_name = "clientvpn"

environment = "dev"

####################################
# Networking
####################################

vpc_cidr = "10.0.0.0/16"

enable_dns_support = true

enable_dns_hostnames = true

app_subnet_cidr = "10.0.1.0/24"

db_subnet_cidr = "10.0.2.0/24"

app_subnet_az = "us-east-1a"

db_subnet_az = "us-east-1b"

####################################
# VPN
####################################

vpn_cidr = "172.16.0.0/22"

####################################
# EC2
####################################

windows_ami = "ami-0b0ea68c435eb488d"

linux_ami = "ami-00ca32bbc84273381"

windows_instance_type = "t3.medium"

linux_instance_type = "t3.micro"

key_name = "clientvpn-key"

####################################
# Tags
####################################

tags = {

  Owner = "Arpit"

  Project = "VPN"

  Environment = "dev"

  Terraform = "true"

}

####################################
# Windows
####################################

windows_instance_name = "windows"

windows_private_ip = "10.0.1.10"

windows_root_volume_size = 100

####################################
# Linux
####################################

linux_instance_name = "linux"

linux_private_ip = "10.0.1.20"

linux_root_volume_size = 30

####################

root_volume_type = "gp3"


#########################################
# VPN
#########################################

vpn_name = "clientvpn-dev"

client_cidr_block = "172.16.0.0/22"

server_certificate_arn = "arn:aws:acm:us-east-1:211811255273:certificate/57ce5bb9-9503-4e80-aa17-8463c2c04f14"

root_certificate_chain_arn = "arn:aws:acm:us-east-1:211811255273:certificate/0ed81d60-469c-4c60-8193-826c8f526650"

transport_protocol = "udp"

vpn_port = 443

split_tunnel = true

session_timeout_hours = 24

dns_servers = []

authorize_all_groups = true

app_ami_id         = "ami-0b46816ffa1234887"
app_instance_type = "t3.micro"
app_subnet_id     = "subnet-03d9268f7580a2070"
app_sg_id         = "sg-002b5f602f4d511bc"
key_name           = "ThreeTierApp"
app_instance_name  = "proj-app-ec2"


region = "eu-north-1"

alb_sg_id = "sg-0ce7e7640c387f725"

public_subnet_ids = [
  "subnet-0e123e973c24fdecf",
  "subnet-04a9f9d40c1e98614"
]


# =========================
# SECURITY GROUP IDS
# (existing – no creation)
# =========================

# ALB / Public-facing SG
#public_sg_id = "sg-0ce7e7640c387f725"

# Application tier SG
#app_sg_id = "sg-002b5f602f4d511bc"

# Database tier SG
db_sg_id  = "sg-09b4fa7e45512a99a"


nat_gateway_id        = "nat-1c803e8cbf90c9ada"
private_route_table_id = "rtb-01950229dbfa4a057"


vpc_id = "vpc-0d06a3a644a12185a"
igw_id = "igw-01952ba2b33377693"

############################
# PUBLIC SUBNETS (ONLY)
############################
public_subnets = {
  "proj-public-subnet-1" = {
    cidr = "10.0.1.0/24"
    az   = "eu-north-1a"
  }

  "proj-public-subnet-2" = {
    cidr = "10.0.2.0/24"
    az   = "eu-north-1b"
  }
}

############################
# PRIVATE SUBNETS (ONLY)
############################
private_subnets = {
  "proj-private-subnet-1" = {
    cidr = "10.0.11.0/24"
    az   = "eu-north-1a"
  }

  "proj-private-subnet-2" = {
    cidr = "10.0.12.0/24"
    az   = "eu-north-1a"   # MUST match AWS
  }
}

############################
# TAGS (OPTIONAL – MUST MATCH AWS)
############################
tags = {
  Project     = "AWS-3Tier"
  Environment = "dev"
}


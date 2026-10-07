module "account_baseline" {
  source = "../../../modules/account-baseline"

  account_name = var.account_name
  environment  = var.environment
  region       = var.aws_region
}

# ============================================================
# IPAM
# ============================================================

resource "aws_vpc_ipam" "enterprise" {
  description = "Enterprise IPAM for centralized private IPv4 management"

  operating_regions {
    region_name = var.aws_region
  }

  tags = {
    Name = "enterprise-ipam"
  }
}

resource "aws_vpc_ipam_pool" "enterprise_private" {
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam.enterprise.private_default_scope_id

  description = "Enterprise private IPv4 address pool"

  allocation_default_netmask_length = 16
  allocation_max_netmask_length     = 16
  allocation_min_netmask_length     = 16

  tags = {
    Name = "enterprise-private-pool"
  }
}

resource "aws_vpc_ipam_pool" "enterprise_us_east_1" {
  address_family      = "ipv4"
  ipam_scope_id       = aws_vpc_ipam.enterprise.private_default_scope_id
  source_ipam_pool_id = aws_vpc_ipam_pool.enterprise_private.id

  locale = var.aws_region

  description = "Enterprise regional IPv4 pool for us-east-1"

  allocation_default_netmask_length = 20
  allocation_max_netmask_length     = 20
  allocation_min_netmask_length     = 20

  tags = {
    Name = "enterprise-us-east-1-pool"
  }
}

resource "aws_vpc_ipam_pool_cidr" "enterprise_private" {
  ipam_pool_id = aws_vpc_ipam_pool.enterprise_private.id
  cidr         = "10.0.0.0/8"
}

resource "aws_vpc_ipam_pool_cidr" "enterprise_us_east_1_primary" {
  ipam_pool_id = aws_vpc_ipam_pool.enterprise_us_east_1.id
  cidr         = "10.0.0.0/16"
}

resource "aws_vpc_ipam_pool_cidr" "enterprise_us_east_1_secondary" {
  ipam_pool_id = aws_vpc_ipam_pool.enterprise_us_east_1.id
  cidr         = "10.1.0.0/20"
}

# ============================================================
# Core Network VPC
# ============================================================

resource "aws_vpc" "network_core" {
  cidr_block           = "10.0.0.0/20"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "network-core-vpc"
  }
}

# ============================================================
# Internet Gateway
# ============================================================

resource "aws_internet_gateway" "network_core" {
  vpc_id = aws_vpc.network_core.id

  tags = {
    Name = "network-core-igw"
  }
}

# ============================================================
# Public Subnets
# ============================================================

resource "aws_subnet" "network_public_a" {
  vpc_id                  = aws_vpc.network_core.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "network-public-a"
    Tier = "public"
  }
}

resource "aws_subnet" "network_public_b" {
  vpc_id                  = aws_vpc.network_core.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "network-public-b"
    Tier = "public"
  }
}

resource "aws_subnet" "network_public_c" {
  vpc_id                  = aws_vpc.network_core.id
  availability_zone       = "us-east-1c"
  cidr_block              = "10.0.6.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "network-public-c"
    Tier = "public"
  }
}

# ============================================================
# Firewall Subnets
# ============================================================

resource "aws_subnet" "network_firewall_a" {
  vpc_id            = aws_vpc.network_core.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = "network-firewall-a"
    Tier = "firewall"
  }
}

resource "aws_subnet" "network_firewall_b" {
  vpc_id            = aws_vpc.network_core.id
  availability_zone = "us-east-1b"
  cidr_block        = "10.0.4.0/24"

  tags = {
    Name = "network-firewall-b"
    Tier = "firewall"
  }
}

resource "aws_subnet" "network_firewall_c" {
  vpc_id            = aws_vpc.network_core.id
  availability_zone = "us-east-1c"
  cidr_block        = "10.0.7.0/24"

  tags = {
    Name = "network-firewall-c"
    Tier = "firewall"
  }
}

# ============================================================
# Private Subnets
# ============================================================

resource "aws_subnet" "network_private_a" {
  vpc_id            = aws_vpc.network_core.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.2.0/24"

  tags = {
    Name = "network-private-a"
    Tier = "private"
  }
}

resource "aws_subnet" "network_private_b" {
  vpc_id            = aws_vpc.network_core.id
  availability_zone = "us-east-1b"
  cidr_block        = "10.0.5.0/24"

  tags = {
    Name = "network-private-b"
    Tier = "private"
  }
}

resource "aws_subnet" "network_private_c" {
  vpc_id            = aws_vpc.network_core.id
  availability_zone = "us-east-1c"
  cidr_block        = "10.0.8.0/24"

  tags = {
    Name = "network-private-c"
    Tier = "private"
  }
}

# ============================================================
# Existing Regional NAT Gateway
#
# Existing NAT:
#   nat-11712dc50368b9016
#
# Regional NAT properties such as:
#   availability_mode
#   auto_scaling_ips
#   auto_provision_zones
#   regional_nat_gateway_auto_mode
#   route_table_id
#
# are computed by AWS/provider and are NOT configurable
# in AWS provider v6.67.0.
# ============================================================

resource "aws_nat_gateway" "network_nat_a" {
  connectivity_type = "public"

  tags = {
    Name = "network-nat-a"
  }
}

# ============================================================
# Existing EIP
# ============================================================

resource "aws_eip" "network_nat_a" {
  domain = "vpc"

  tags = {
    Name = "network-nat-a-eip"
  }
}

# ============================================================
# NAT Gateway Route Table
#
# Existing:
#   rtb-0b356d9464bf0ed99
#
# This route table is associated with the Regional NAT Gateway.
# ============================================================

resource "aws_route_table" "network_nat" {
  vpc_id = aws_vpc.network_core.id

  tags = {
    Name = "network-nat-rt"
  }
}

# ============================================================
# Public Route Table
# ============================================================

resource "aws_route_table" "network_public" {
  vpc_id = aws_vpc.network_core.id

  tags = {
    Name = "network-public-rt"
  }
}

resource "aws_route" "network_public_default" {
  route_table_id         = aws_route_table.network_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.network_core.id
}

# ============================================================
# Firewall Route Table
# ============================================================

resource "aws_route_table" "network_firewall" {
  vpc_id = aws_vpc.network_core.id

  tags = {
    Name = "network-firewall-rt"
  }
}

# ============================================================
# Private Route Table
# ============================================================

resource "aws_route_table" "network_private" {
  vpc_id = aws_vpc.network_core.id

  tags = {
    Name = "network-private-rt"
  }
}

resource "aws_route" "network_private_default" {
  route_table_id         = aws_route_table.network_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.network_nat_a.id
}

# ============================================================
# Public Subnet Associations
# ============================================================

resource "aws_route_table_association" "network_public_a" {
  subnet_id      = aws_subnet.network_public_a.id
  route_table_id = aws_route_table.network_public.id
}

resource "aws_route_table_association" "network_public_b" {
  subnet_id      = aws_subnet.network_public_b.id
  route_table_id = aws_route_table.network_public.id
}

resource "aws_route_table_association" "network_public_c" {
  subnet_id      = aws_subnet.network_public_c.id
  route_table_id = aws_route_table.network_public.id
}

# ============================================================
# Firewall Subnet Associations
# ============================================================

resource "aws_route_table_association" "network_firewall_a" {
  subnet_id      = aws_subnet.network_firewall_a.id
  route_table_id = aws_route_table.network_firewall.id
}

resource "aws_route_table_association" "network_firewall_b" {
  subnet_id      = aws_subnet.network_firewall_b.id
  route_table_id = aws_route_table.network_firewall.id
}

resource "aws_route_table_association" "network_firewall_c" {
  subnet_id      = aws_subnet.network_firewall_c.id
  route_table_id = aws_route_table.network_firewall.id
}

# ============================================================
# Private Subnet Associations
# ============================================================

resource "aws_route_table_association" "network_private_a" {
  subnet_id      = aws_subnet.network_private_a.id
  route_table_id = aws_route_table.network_private.id
}

resource "aws_route_table_association" "network_private_b" {
  subnet_id      = aws_subnet.network_private_b.id
  route_table_id = aws_route_table.network_private.id
}

resource "aws_route_table_association" "network_private_c" {
  subnet_id      = aws_subnet.network_private_c.id
  route_table_id = aws_route_table.network_private.id
}

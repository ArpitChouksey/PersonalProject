# VPC
import {
  to = module.vpc.aws_vpc.this
  id = "vpc-074db46afdba5d9c6"
}

# Subnets
import {
  to = module.subnet.aws_subnet.this["PublicSubnet"]
  id = "subnet-0ee70136087fc8bf7"
}

import {
  to = module.subnet.aws_subnet.this["AppSubnet"]
  id = "subnet-060bc710412df5d15"
}

import {
  to = module.subnet.aws_subnet.this["DatabaseSubnet"]
  id = "subnet-0ff92d9be4391395f"
}

# Internet Gateway
import {
  to = module.internet_gateway.aws_internet_gateway.this
  id = "igw-0bf931f2a1d12156b"
}

# Route Tables
import {
  to = module.route_table.aws_route_table.this["rt-public"]
  id = "rtb-07521754a093c2c44"
}

import {
  to = module.route_table.aws_route_table.this["rt-app"]
  id = "rtb-00b1931b586b26147"
}

import {
  to = module.route_table.aws_route_table.this["rt-database"]
  id = "rtb-0cd033f223f5d8e97"
}

# Security Groups
import {
  to = module.security_group.aws_security_group.this["migration-app"]
  id = "sg-0ce0aba5ad90172ad"
}

import {
  to = module.security_group.aws_security_group.this["migration-db"]
  id = "sg-033cf24f18e701467"
}

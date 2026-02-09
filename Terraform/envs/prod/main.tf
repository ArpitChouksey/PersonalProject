#################################
# VPC
#################################
module "vpc" {
  source     = "../../modules/network/vpc"
  cidr_block = var.vpc_cidr
  name       = var.vpc_name
}

#################################
# Subnets
#################################
module "subnets" {
  source = "../../modules/network/subnets"
  vpc_id = module.vpc.vpc_id
  subnets = var.subnets
}

#################################
# Internet Gateway
#################################
module "igw" {
  source = "../../modules/network/internet-gateway"
  vpc_id = module.vpc.vpc_id
  name   = var.igw_name
}

#################################
# PUBLIC ROUTES ONLY
#################################
module "route_tables" {
  source = "../../modules/network/route-tables"

  vpc_id = module.vpc.vpc_id
  igw_id = module.igw.igw_id

  public_subnet_ids = [
    module.subnets.subnet_ids["public-subnet-a"],
    module.subnets.subnet_ids["public-subnet-b"]
  ]
}

#################################
# PRIVATE NAT ROUTE (IMPORT ONLY)
#################################
module "private_nat_route" {
  source = "../../modules/network/private-nat-route"

  private_route_table_id = "rtb-034be1bb8f5460123"
  nat_gateway_id         = "nat-129a62da351899b12"
}

#################################
# IAM
#################################
module "terraform_role" {
  source = "../../modules/iam/terraform-role"
}

module "eks_cluster_role" {
  source = "../../modules/iam/eks-cluster-role"
}

module "eks_node_role" {
  source = "../../modules/iam/eks-node-role"
}

#################################
# ECR
#################################
module "ecr" {
  source = "../../modules/ecr"
}

#################################
# EKS CLUSTER
#################################
module "eks" {
  source = "../../modules/eks"

  cluster_name       = "eks-prod-cluster"
  cluster_role_arn   = "arn:aws:iam::211811255273:role/eks-cluster-role"
  kubernetes_version = "1.34"

  subnet_ids = [
    "subnet-01dd7d1ccb02292b6",
    "subnet-0cf4901bc3523e68f"
  ]

  endpoint_private_access = false
  endpoint_public_access  = true

  cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

#################################
# EKS NODE
#################################

module "eks_node_group" {
  source = "../../modules/eks-node-group"

  cluster_name    = "eks-prod-cluster"
  node_group_name = "eks-prod-ng-1"
  node_role_arn   = "arn:aws:iam::211811255273:role/eks-node-role"

  subnet_ids = [
    "subnet-01dd7d1ccb02292b6",
    "subnet-0cf4901bc3523e68f"
  ]
}


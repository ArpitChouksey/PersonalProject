module "vpc" {
  source = "./modules/vpc"

  vpc_id                 = var.vpc_id
  igw_id                 = var.igw_id
  nat_gateway_id         = var.nat_gateway_id
  private_route_table_id = var.private_route_table_id

  alb_sg_id = var.alb_sg_id
  app_sg_id = var.app_sg_id
  db_sg_id  = var.db_sg_id

  public_subnet_ids = var.public_subnet_ids
  public_subnets    = var.public_subnets
  private_subnets   = var.private_subnets

  tags = var.tags
}


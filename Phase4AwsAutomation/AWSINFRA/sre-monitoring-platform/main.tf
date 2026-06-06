module "vpc" {
  source = "./modules/vpc"
}

module "security_group" {

  source = "./modules/security-group"

  vpc_id = module.vpc.vpc_id

  sg_name        = var.sg_name
  sg_description = var.sg_description

  allowed_ip    = var.allowed_ip
  allowed_ports = var.allowed_ports
}

module "iam" {
  source = "./modules/iam"

  cluster_role_name = var.cluster_role_name
  node_role_name    = var.node_role_name
}

module "ec2" {
  source = "./modules/ec2"

  subnet_id         = module.vpc.public_subnet_a
  security_group_id = module.security_group.sg_id

  instance_type = var.instance_type
  instance_name = var.instance_name
  ami_id        = var.ami_id
}

module "eks" {

  source = "./modules/eks"

  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name

  # IMPORTANT: Match imported AWS state
  cluster_role_arn = module.iam.node_role_arn

  node_role_arn = module.iam.node_role_arn

  subnet_ids = [
    module.vpc.public_subnet_a,
    module.vpc.public_subnet_b,
    module.vpc.private_subnet_a,
    module.vpc.private_subnet_b
  ]

  private_subnet_a = module.vpc.private_subnet_a
  private_subnet_b = module.vpc.private_subnet_b

  desired_size = 1
  min_size     = 1
  max_size     = 2

  instance_types = var.instance_types
}

module "cloudwatch" {
  source = "./modules/cloudwatch"

  instance_id   = module.ec2.instance_id
  sns_topic_arn = module.sns.topic_arn
}

module "cloudtrail" {
  source = "./modules/cloudtrail"

  trail_name             = var.trail_name
  cloudtrail_bucket_name = var.cloudtrail_bucket_name
}

module "dynamodb" {

  source = "./modules/dynamodb"

  table_name  = var.dynamodb_table_name

  billing_mode = var.dynamodb_billing_mode
}

module "sns" {

  source = "./modules/sns"

  topic_name = var.topic_name

  email = var.email_address
}

module "ecr" {
  source = "./modules/ecr"

  repository_name = "sre-project"

  tags = {
    Project = "SRE-Monitoring"
  }
}

module "alb_controller" {
  source = "./modules/alb-controller"

  policy_name = "AWSLoadBalancerControllerIAMPolicy"
}

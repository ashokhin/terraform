terraform {
  backend "s3" {
    bucket = var.tf_state_bucket
    key    = "${var.tf_state_base_path}/terraform.tfstate"
    region = var.tf_state_region
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "ap_east_1"
  region = "ap-east-1"
}

provider "aws" {
  alias  = "eu_central_1"
  region = "eu-central-1"
}

module "aws_network_dev_default" {
  source                  = "../../modules/aws_network"
  env                     = var.env
  vpc_cidr                = var.base_cidr_block
  subnets_additional_bits = 8
  create_public_subnets   = true
  create_private_subnets  = false
}

module "aws_autoscaling_group_default" {
  source         = "../../modules/aws_autoscaling"
  env            = var.env
  ec2_type       = var.ec2_type
  vpc_id         = module.aws_network_dev_default.vpc.id
  vpc_cidr_block = module.aws_network_dev_default.vpc.cidr_block
  vpc_zone_ids   = module.aws_network_dev_default.public_subnets[*].id
  open_ports     = var.open_ports
  min_size       = var.asg_min_size
  max_size       = var.asg_max_size
  desired_size   = var.asg_desired_size
}

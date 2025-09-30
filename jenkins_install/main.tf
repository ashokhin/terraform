/*
# Store Terraform state remotely into S3 bucket
terraform {
  backend "s3" {
    bucket = var.tf_state_bucket
    key    = "${var.tf_state_base_path}/terraform.tfstate"
    region = var.tf_state_region
  }
}
*/

provider "aws" {
  region = var.aws_region
}

locals {
  jenkins_fqdn = "${var.jenkins_subdomain}.${var.jenkins_root_domain}"
}

# Create network for Jenkins (VPC, IGW, NAT GW, private networks, public networks, route tables)
module "aws_network_jenkins" {
  source                  = "../modules/aws_network"
  env                     = var.env
  vpc_cidr                = var.base_cidr_block
  subnets_additional_bits = 8
  create_public_subnets   = true
  create_private_subnets  = false
}

# Create registration point for "Let's Encrypt" TLS certificate
module "aws_acme_jenkins" {
  source           = "../modules/aws_acme"
  env              = var.env
  acme_root_domain = "andreishokhin.online"
  acme_subdomain   = "jenkins"
}

# Create Jenkins instance
module "aws_jenkins_default" {
  source              = "../modules/aws_jenkins"
  depends_on          = [module.aws_network_jenkins, module.aws_acme_jenkins]
  env                 = var.env
  ec2_type            = var.ec2_type
  vpc_id              = module.aws_network_jenkins.vpc.id
  vpc_cidr_block      = module.aws_network_jenkins.vpc.cidr_block
  vpc_zone_ids        = module.aws_network_jenkins.public_subnets[*].id
  open_ports          = var.open_ports
  acme_certificate    = module.aws_acme_jenkins.acme_certificate
  tls_enabled         = true
  jenkins_fqdn        = module.aws_acme_jenkins.acme_fqdn
  jenkins_root_domain = module.aws_acme_jenkins.acme_root_domain
}

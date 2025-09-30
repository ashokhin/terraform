

output "module_aws_network_dev_default" {
  value = {
    vpc              = module.aws_network_dev_default.vpc
    public_subnets   = module.aws_network_dev_default.public_subnets
    private_subnets  = module.aws_network_dev_default.private_subnets
    internet_gateway = module.aws_network_dev_default.internet_gateway
    eip              = module.aws_network_dev_default.eip
    nat_gateway      = module.aws_network_dev_default.nat_gateway
  }
}

output "aws_autoscaling_group_default" {
  value = {
    id                   = module.aws_autoscaling_group_default.autoscaling_group.id
    name                 = module.aws_autoscaling_group_default.autoscaling_group.name
    instances_public_ips = module.aws_autoscaling_group_default.instances.public_ips
    ssh_key              = module.aws_autoscaling_group_default.ssh_key
  }
}

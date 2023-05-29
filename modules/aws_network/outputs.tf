output "vpc" {
  value = {
    cidr_block = aws_vpc.main.cidr_block
    id         = aws_vpc.main.id
  }
}

output "public_subnets" {
  value = [
    for sub in aws_subnet.public_subnets :
    {
      availability_zone = sub.availability_zone
      cidr_block        = sub.cidr_block
      id                = sub.id
      vpc_id            = sub.vpc_id
    }
  ]
}

output "private_subnets" {
  value = [
    for sub in aws_subnet.private_subnets :
    {
      availability_zone = sub.availability_zone
      cidr_block        = sub.cidr_block
      id                = sub.id
      vpc_id            = sub.vpc_id
    }
  ]
}

output "internet_gateway" {
  value = {
    id     = aws_internet_gateway.main.id
    vpc_id = aws_internet_gateway.main.vpc_id
  }
}

output "eip" {
  value = [
    for eip in aws_eip.nat :
    {
      domain               = eip.domain
      id                   = eip.id
      network_border_group = eip.network_border_group
      public_dns           = eip.public_dns
      public_ip            = eip.public_ip
    }
  ]
}

output "nat_gateway" {
  value = [
    for ngw in aws_nat_gateway.nat :
    {
      allocation_id     = ngw.allocation_id
      connectivity_type = ngw.connectivity_type
      id                = ngw.id
      public_ip         = ngw.public_ip
      subnet_id         = ngw.subnet_id
    }
  ]
}

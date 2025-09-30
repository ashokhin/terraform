#
# Terraform module for creating AWS network
#
# Provision:
# - VPC
# - Internet Gateway
# - N Public Subnets ("N" depends on number of availability zones)
# - N Private subnets ("N" depends on number of availability zones)
# - N NAT Gateways in Public Subnets
#

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.14.1"
    }
  }
}

# Get availability zones from AWS region
data "aws_availability_zones" "available" {}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = merge(var.tags, { Name = "tf-${var.env}-vpc" })
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "tf-${var.env}-igw" })
}

# Create public subnets
resource "aws_subnet" "public_subnets" {
  count                   = var.create_public_subnets ? length(data.aws_availability_zones.available.names) : 0
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.subnets_additional_bits, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "tf-${var.env}-public-${count.index + 1}" })
}

# Create routing tables for public subnets to Internet Gateways
resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = merge(var.tags, { Name = "tf-${var.env}-public-rt" })
}

# Create route association between route tables and public subnets
resource "aws_route_table_association" "public_routes" {
  count          = length(aws_subnet.public_subnets)
  route_table_id = aws_route_table.public_subnets.id
  subnet_id      = aws_subnet.public_subnets[count.index].id
}

# Create Elastic IPs for NAT gateways
resource "aws_eip" "nat" {
  count  = length(aws_subnet.private_subnets)
  domain = "vpc"
  tags   = merge(var.tags, { Name = "tf-${var.env}-nat-gw-${count.index + 1}" })
}

# Create NAT gateways with Elastic IPs
resource "aws_nat_gateway" "nat" {
  count         = length(aws_subnet.private_subnets)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id
  tags          = merge(var.tags, { Name = "tf-${var.env}-nat-gw-${count.index + 1}" })
}

# Create private subnets
resource "aws_subnet" "private_subnets" {
  count             = var.create_private_subnets ? length(data.aws_availability_zones.available.names) : 0
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnets_additional_bits, (count.index + (var.create_public_subnets ? length(data.aws_availability_zones.available.names) : 0)))
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags              = merge(var.tags, { Name = "tf-${var.env}-private-${count.index + 1}" })
}

# Create routing tables for private subnets to NAT gateways
resource "aws_route_table" "private_subnets" {
  count  = var.create_private_subnets ? length(data.aws_availability_zones.available.names) : 0
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = merge(var.tags, { Name = "tf-${var.env}-private-rt-${count.index + 1}" })
}

# Create route association between route tables and private subnets
resource "aws_route_table_association" "private_routes" {
  count          = length(aws_subnet.private_subnets)
  route_table_id = aws_route_table.private_subnets[count.index].id
  subnet_id      = aws_subnet.private_subnets[count.index].id
}

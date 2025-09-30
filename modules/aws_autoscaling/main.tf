#
# Terraform module for creating AWS Auto Scaling group
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
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1.0"
    }
  }
}

# Get list of AWS availability zones in current region
data "aws_availability_zones" "available" {}

# Get latest Amazon Machine Image of "Amazon Linux"
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }
}

# Get latest Amazon Machine Image of "Debian Linux"
data "aws_ami" "latest_debian_linux" {
  owners      = ["136693071363"]
  most_recent = true
  filter {
    name   = "name"
    values = ["debian-11-amd64-*"]
  }
}

data "aws_instances" "asg" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.main.name]
  }
}

# Generate SSH key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Write SSH key to AWS key pairs
resource "aws_key_pair" "generated" {
  public_key = tls_private_key.ssh.public_key_openssh
  tags = merge(var.tags, {
    Name = "tf-${var.env}-Generated SSH-key"
  })
}

# Create AWS security group, open 22 port
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.open_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0", var.vpc_cidr_block]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    # Necessary if changing 'name' or 'name_prefix' properties.
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "tf-${var.env}-allow_ssh-sg"
  })
}

# Create Launch Template for Auto Scaling group
resource "aws_launch_template" "main" {
  name_prefix            = "test"
  image_id               = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.ec2_type
  key_name               = aws_key_pair.generated.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = merge(var.tags, {
    Name = "tf-${var.env}-launch-template"
  })
}

# Create Auto Scaling group from Launch Template
resource "aws_autoscaling_group" "main" {
  name_prefix         = "test"
  vpc_zone_identifier = var.vpc_zone_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_size
  launch_template {
    id      = aws_launch_template.main.id
    version = aws_launch_template.main.latest_version
  }

  dynamic "tag" {
    for_each = merge(var.tags, {
      Name = "tf-${var.env}-server in ASG"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

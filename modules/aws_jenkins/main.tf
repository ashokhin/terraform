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

# Get latest Amazon Machine Image of "Ubuntu Linux"
data "aws_ami" "latest_ubuntu_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-*"]
  }
}

# Search for IAM assume role policy document for EC2
data "aws_iam_policy_document" "certbot_assume_document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Create IAM policy
resource "aws_iam_policy" "certbot_policy" {
  name        = "EC2RenewAcmCertificatePolicy"
  description = "Policy for EC2 instance for import certificate to AWS ACM"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "acm:DescribeCertificate",
          "acm:UpdateCertificateOptions",
          "acm:ImportCertificate",
          "acm:ListTagsForCertificate"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "acm:ListCertificates",
        "Resource" : "*"
      }
    ]
  })

  tags = merge(var.tags, { Name = "tf-iam-policy-${var.env}-cert" })
}

# Create IAM role with policy from generated data
resource "aws_iam_role" "certbot" {
  name                = "EC2RenewJenkinsACMCertsRole"
  assume_role_policy  = data.aws_iam_policy_document.certbot_assume_document.json
  managed_policy_arns = [aws_iam_policy.certbot_policy.arn]
  tags                = merge(var.tags, { Name = "tf-iam-role-${var.env}-cert" })
}

resource "aws_iam_instance_profile" "certbot" {
  name = "EC2RenewAcmCertificate"
  role = aws_iam_role.certbot.name
}

# Generate SSH key
resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

# Write SSH key to AWS key pairs
resource "aws_key_pair" "generated" {
  public_key = tls_private_key.ssh.public_key_openssh
  tags       = merge(var.tags, { Name = "tf-key-${var.module_name}-${var.env}-Generated SSH-key" })
}

# Create AWS security group, with open internal tcp ports
resource "aws_security_group" "internal" {
  name        = "${var.module_name}-${var.env}-open-internal-ports"
  description = "Allow ${var.module_name}-${var.env} inbound traffic"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.open_ports
    content {
      from_port   = ingress.value.internal_port
      to_port     = ingress.value.internal_port
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
    Name = "tf-sg-${var.module_name}-${var.env}-allow-internal-ports"
  })
}

# Create AWS security group, with open external tcp ports
resource "aws_security_group" "external" {
  name        = "${var.module_name}-${var.env}-open-external-ports"
  description = "Allow ${var.module_name}-${var.env} inbound traffic"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.open_ports
    content {
      from_port   = ingress.value.external_port
      to_port     = ingress.value.external_port
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
    Name = "tf-sg-${var.module_name}-${var.env}-allow-external-ports"
  })
}

# Create jenkins instance and install Java and Jenkins with user_data
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.latest_ubuntu_linux.id
  instance_type          = var.ec2_type
  iam_instance_profile   = aws_iam_instance_profile.certbot.id
  key_name               = aws_key_pair.generated.key_name
  subnet_id              = var.vpc_zone_ids[0]
  vpc_security_group_ids = [aws_security_group.internal.id]

  # user_data = file("${path.module}/files/install_jenkins.sh")

  connection {
    user        = "ubuntu"
    type        = "ssh"
    private_key = tls_private_key.ssh.private_key_pem
    host        = aws_instance.jenkins.public_ip
  }

  provisioner "remote-exec" {

    inline = [
      # update repos & upgrade packages
      "sudo apt update && sudo apt -y upgrade",
      # Install Java 21 JDK
      "sudo apt install -y fontconfig openjdk-21-jre",
      # Add Jenkins repo key
      "curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /etc/apt/keyrings/jenkins-keyring.asc > /dev/null",
      # Add Jenkins LTS repo
      "echo deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
      # Update repos
      "sudo apt update",
      # Install Jenkins
      "sudo apt install -y jenkins",
      # Enable and start Jenkins service
      "sudo systemctl enable jenkins.service --now",
    ]

  }
  tags = merge(var.tags, {
    Name = "tf-ec2-${var.module_name}-${var.env}"
  })
}

# Create certificate in Amazon Certificate Management if TLS is enabled
resource "aws_acm_certificate" "certificate" {
  # If TLS is enabled then create certificate
  count = var.tls_enabled ? 1 : 0

  certificate_body  = var.acme_certificate.certificate_pem
  private_key       = var.acme_certificate.private_key_pem
  certificate_chain = var.acme_certificate.issuer_pem
}

# Create target groups for load balancer
resource "aws_lb_target_group" "jenkins" {
  for_each = var.open_ports
  port     = each.value.internal_port
  protocol = each.value.protocol
  vpc_id   = var.vpc_id

  tags = merge(var.tags, {
    Name = "tf-tg-${var.module_name}-${var.env}-${each.key}"
  })
}

# Attach jenkins EC2 instance to created target groups
resource "aws_lb_target_group_attachment" "jenkins" {
  for_each         = var.open_ports
  target_group_arn = aws_lb_target_group.jenkins[each.key].arn
  target_id        = aws_instance.jenkins.id
  port             = each.value.internal_port
}

# Create application load balancer if TLS is enabled
resource "aws_lb" "alb_jenkins" {
  # If TLS is enabled then create application load balancer
  count = var.tls_enabled ? 1 : 0

  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.external.id]
  subnets            = var.vpc_zone_ids

  tags = merge(var.tags, {
    Name = "tf-alb-${var.module_name}-${var.env}"
  })
}

# Create HTTPS listener with certificate if TLS is enabled and link it with target group
resource "aws_lb_listener" "alb_jenkins" {
  # If TLS is enabled then create a HTTPS listener
  count = var.tls_enabled ? 1 : 0

  load_balancer_arn = aws_lb.alb_jenkins[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.certificate[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins["HTTP"].arn
  }

  tags = merge(var.tags, {
    Name = "tf-lb-listener-${var.module_name}-${var.env}"
  })
}

# Search hosted zone in Route53
data "aws_route53_zone" "selected" {
  name         = var.jenkins_root_domain
  private_zone = false
}

# Create new DNS alias for HTTPS listener if TLS is enabled
resource "aws_route53_record" "jenkins" {
  # If TLS is enabled then create a DNS alias
  count = var.tls_enabled ? 1 : 0

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.jenkins_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.alb_jenkins[0].dns_name
    zone_id                = aws_lb.alb_jenkins[0].zone_id
    evaluate_target_health = false
  }
}

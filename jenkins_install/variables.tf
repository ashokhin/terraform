variable "env" {
  default     = "dev"
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  default     = "us-east-2"
  description = "AWS region (ex.: us-east-1, us-west-1 etc.)"
  type        = string
}

variable "jenkins_root_domain" {
  default = "andreishokhin.online"
  type    = string
}

variable "jenkins_subdomain" {
  default = "jenkins"
  type    = string
}

variable "base_cidr_block" {
  default = "10.0.0.0/16"
  type    = string
}

variable "ec2_type" {
  default     = "t2.micro"
  description = "EC2 instance type (ex.: t1.micro, t2.micro etc.)"
  type        = string
}

variable "open_ports" {
  default = {
    "HTTP" = {
      internal_port = 8080
      external_port = 443
      protocol      = "HTTP"
    },
    "TCP" = {
      internal_port = 22
      external_port = 22
      protocol      = "TCP"
    },
  }
  description = "List of open ports on instance"
  type = map(object({
    internal_port = number
    external_port = number
    protocol      = string
  }))
}

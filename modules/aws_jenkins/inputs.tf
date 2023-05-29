variable "env" {
  description = "Environment name"
  type        = string
}

variable "ec2_type" {
  description = "Instance type for Jenkins EC2 Instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
}

variable "vpc_zone_ids" {
  description = "List of VPC zone IDs"
  type        = list(string)
}

variable "open_ports" {
  description = "Set of internal and external open ports"
  type = map(object({
    internal_port = number
    external_port = number
    protocol      = string
  }))
}

variable "acme_certificate" {
  type = map(string)
  default = {
    certificate_pem = ""
    private_key_pem = ""
    issuer_pem      = ""
  }
}

variable "tls_enabled" {
  type        = bool
  default     = false
  description = "If TLS enabled than create certificate certificate from variable `acme_certificate`"
}

variable "jenkins_fqdn" {
  type    = string
  default = ""
}

variable "jenkins_root_domain" {
  type    = string
  default = ""
}

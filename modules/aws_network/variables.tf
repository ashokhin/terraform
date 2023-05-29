variable "env" {
  default     = "dev"
  description = "Environment name will be used for tags"
  type        = string
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "VPC CIDR block will be used for AWS VPC"
  type        = string
}

variable "subnets_additional_bits" {
  default     = 8
  description = "Number of additional bits with which to extend the prefix. For example, if given a prefix ending in /16 and a value of 8, the resulting subnet address will have length /24."
  type        = number
}

variable "create_public_subnets" {
  default     = true
  description = "Create public subnet for each availability zone"
  type        = bool
}

variable "create_private_subnets" {
  default     = false
  description = "Create private subnet for each availability zone"
  type        = bool
}

variable "tags" {
  default = {
    Owner     = "Andrei Shokhin"
    ManagedBy = "Terraform"
    TFModule  = "aws_network"
  }
}

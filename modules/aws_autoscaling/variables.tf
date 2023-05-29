variable "env" {
  description = "Environment name"
  type        = string
}

variable "ec2_type" {
  description = "Instance type for Auto Scaling group"
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
  description = "List of open ports"
  type        = list(string)
}
variable "tags" {
  default = {
    Owner     = "Andrei Shokhin"
    ManagedBy = "Terraform"
    TFModule  = "aws_autoscaling"
  }
}

variable "min_size" {
  default     = 1
  description = "Minimum capacity. Represents the minimum group size"
}

variable "max_size" {
  default     = 3
  description = "Maximum capacity. Represents the maximum group size"
}

variable "desired_size" {
  default     = 2
  description = "Desired capacity. Represents the initial capacity of the Auto Scaling group at the time of creation"
}

variable "tf_state_bucket" {
  type    = string
  default = "076077344254-terraform-state"
}

variable "tf_state_base_path" {
  type    = string
  default = "autoscaling_install/development"
}

variable "tf_state_region" {
  type    = string
  default = "us-east-1"
}

variable "env" {
  default     = "dev"
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  default     = "us-east-1"
  description = "AWS region (ex.: us-east-1, us-west-1 etc.)"
  type        = string
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
  default     = ["22", "80", "443"]
  description = "List of open ports on instances"
  type        = list(string)
}

variable "asg_min_size" {
  default     = 1
  description = "Minimum capacity. Represents the minimum group size"
}

variable "asg_max_size" {
  default     = 3
  description = "Maximum capacity. Represents the maximum group size"
}

variable "asg_desired_size" {
  default     = 2
  description = "Desired capacity. Represents the initial capacity of the Auto Scaling group at the time of creation"
}

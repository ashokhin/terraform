variable "module_name" {
  type    = string
  default = "aws_jenkins"
}

variable "tags" {
  type = map(string)
  default = {
    Owner           = "Andrei Shokhin"
    ManagedBy       = "Terraform"
    TerraformModule = "aws_jenkins"
  }
}

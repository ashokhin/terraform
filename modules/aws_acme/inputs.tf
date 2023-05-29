variable "env" {
  type        = string
  default     = ""
  description = "Environment name"
}

variable "acme_root_domain" {
  type        = string
  default     = "example.com"
  description = "Root domain name (default: `example.com`)"
}

variable "acme_subdomain" {
  type        = string
  default     = ""
  description = "Sub-domain name (default: `None`)"
}

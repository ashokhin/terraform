variable "acme_server_url" {
  type    = string
  default = "https://acme-staging-v02.api.letsencrypt.org/directory"
  # default = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "acme_key_algorithm" {
  type        = string
  default     = "RSA"
  description = "Name of the algorithm to use when generating the private key. Currently-supported values are: RSA, ECDSA, ED25519."
}

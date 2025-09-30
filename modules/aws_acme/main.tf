terraform {
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.36.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1.0"
    }
  }
}

provider "acme" {
  server_url = var.acme_server_url
}

locals {
  subdomain_with_env    = var.env != "" ? (var.acme_subdomain != "" ? "${var.acme_subdomain}-${var.env}.${var.acme_root_domain}" : "") : ""
  subdomain_without_env = var.acme_subdomain != "" ? "${var.acme_subdomain}.${var.acme_root_domain}" : ""
  acme_fqdn             = coalesce(local.subdomain_with_env, local.subdomain_without_env)
}

resource "tls_private_key" "private_key" {
  algorithm = var.acme_key_algorithm
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = "nobody@${var.acme_root_domain}"
}

resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = local.acme_fqdn != "" ? local.acme_fqdn : "www.${var.acme_root_domain}"
  subject_alternative_names = [local.acme_fqdn != "" ? local.acme_fqdn : "www2.${var.acme_root_domain}"]

  dns_challenge {
    provider = "route53"
  }
}

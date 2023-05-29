output "certificate_pem" {
  value = lookup(acme_certificate.certificate, "certificate_pem")
}

output "issuer_pem" {
  value = lookup(acme_certificate.certificate, "issuer_pem")
}

output "private_key_pem" {
  value = nonsensitive(lookup(acme_certificate.certificate, "private_key_pem"))
}

output "acme_certificate" {
  value = {
    certificate_pem = acme_certificate.certificate.certificate_pem
    issuer_pem      = acme_certificate.certificate.issuer_pem
    private_key_pem = nonsensitive(acme_certificate.certificate.private_key_pem)
  }
}

output "acme_fqdn" {
  value = local.acme_fqdn
}

output "acme_root_domain" {
  value = var.acme_root_domain
}

output "debug_output" {
  value = data.aws_ami.latest_ubuntu_linux
}

output "debug_instance" {
  value = aws_instance.jenkins
}

output "ssh_key" {
  value = nonsensitive(tls_private_key.ssh.private_key_pem)
}

output "instance" {
  value = {
    public_ip = aws_instance.jenkins.public_ip
  }
}
output "acme_certificate" {
  value = var.acme_certificate
}

output "route53_data" {
  value = data.aws_route53_zone.selected
}

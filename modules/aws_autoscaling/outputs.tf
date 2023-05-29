output "autoscaling_group" {
  value = {
    id   = aws_autoscaling_group.main.id
    name = aws_autoscaling_group.main.name

  }
}

output "instances" {
  value = {
    public_ips = data.aws_instances.asg.public_ips
  }
}

output "ssh_key" {
  value = nonsensitive(tls_private_key.ssh.private_key_pem)
}

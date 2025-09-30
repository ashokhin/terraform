output "debug_jenkins" {
  value = {
    ssh_key   = module.aws_jenkins_default.ssh_key
    public_ip = module.aws_jenkins_default.instance.public_ip
  }
}

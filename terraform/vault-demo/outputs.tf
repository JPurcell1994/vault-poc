output "ec2_private_ip" {
  value = module.vault-demo.ec2_private_ip
  description = "Private IP of the instance created"
}

output "ec2_id" {
  value = module.vault-demo.ec2_id
  description = "ID of the instance created"
}

output "ec2_ssh_key" {
  value = module.vault-demo.ec2_ssh_key_name
  description = "Key Pair Name attached to the instance"
}
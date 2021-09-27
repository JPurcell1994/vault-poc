output "ec2_id" {
  value = aws_instance.vault.id
  description = "ID of the instance created"
}

output "ec2_private_ip" {
  value = aws_instance.vault.private_ip
  description = "Private IP of the instance created"
}

output "ec2_ssh_key_name" {
  value = aws_instance.vault.key_name
  description = "Key Pair Name attached to the instance"
}
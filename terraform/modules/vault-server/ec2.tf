resource "aws_instance" "vault" {
  ami           = data.aws_ami.vault.id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  key_name = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = var.instance_name
  }
}
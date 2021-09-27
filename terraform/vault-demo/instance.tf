module "vault-demo" {
  source = "../modules/vault-server"

  aws_region = ""
  vpc_id = ""
  subnet_id = ""

  ami_prefix = ""
  ssh_key_name = ""
  instance_name = ""
  instance_type = ""

  security_group_ingress = []
  security_group_egress = []
  security_group_description = ""
  security_group_name = ""
}
data "aws_ami" "vault" {
  most_recent = true
  owners = [
    "self"]

  filter {
    name = "name"
    values = [
      var.ami_prefix]
  }
}
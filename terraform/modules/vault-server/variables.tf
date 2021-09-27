#### AWS Variables

variable "aws_region" {
  type = string
  description = "Region in which you'll be building the instance, us-east-1, eu-west-1 etc"
}

#### Instance Variables

variable "ami_prefix" {
  type = string
  description = "Prefix for the AMI to be used"
}

variable "instance_type" {
  type = string
  description = "Instance Type to be used"
}

variable "ssh_key_name" {
  type = string
  description = "Name of the key-pair to be attached to the instance"
}

variable "instance_name" {
  type = string
  description = "Name of the instance to appear in Amazon UI"
}

#### VPC Variables

variable "vpc_id" {
  type = string
  description = "ID of the VPC the Instance and Security Group will live in"
}

variable "subnet_id" {
  type = string
  description = "ID of the Subnet the Instance and Security Group will live in"
}

#### Security Group Variables

variable "security_group_ingress" {
  type = list(string)
  description = "List of strings of CIDR blocks, for which SSH to the instance is approved"
}

variable "security_group_egress" {
  type = list(string)
  description = "List of strings of CIDR blocks, for which outbound connections are approved from the instance"
  default = ["0.0.0.0"]
}

variable "security_group_name" {
  type = string
  description = "Name of the security group. If omitted, Terraform will assign a random, unique name."
  default = "vault-ssh-sg"
}

variable "security_group_description" {
  type = string
  description = "Security group description. Defaults to Managed by Terraform"
  default = "Security group to allow SSH to the instance"
}
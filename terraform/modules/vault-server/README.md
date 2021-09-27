# terraform/modules/instance

This is a module to create an EC2 instance. It will attach a security group which allows SSH from a specified CIDR block. For further technical information see below.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |
| aws | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.0 |

## Modules

No Modules.

## Resources

| Name |
|------|
| [aws_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) |
| [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) |
| [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ami\_prefix | Prefix for the AMI to be used | `string` | n/a | yes |
| aws\_region | Region in which you'll be building the instance, us-east-1, eu-west-1 etc | `string` | n/a | yes |
| instance\_name | Name of the instance to appear in Amazon UI | `string` | n/a | yes |
| instance\_type | Instance Type to be used | `string` | n/a | yes |
| security\_group\_description | Security group description. Defaults to Managed by Terraform | `string` | `"Security group to allow SSH to the instance"` | no |
| security\_group\_egress | List of strings of CIDR blocks, for which outbound connections are approved from the instance | `list(string)` | <pre>[<br>  "0.0.0.0"<br>]</pre> | no |
| security\_group\_ingress | List of strings of CIDR blocks, for which SSH to the instance is approved | `list(string)` | n/a | yes |
| security\_group\_name | Name of the security group. If omitted, Terraform will assign a random, unique name. | `string` | `"vault-ssh-sg"` | no |
| ssh\_key\_name | Name of the key-pair to be attached to the instance | `string` | n/a | yes |
| subnet\_id | ID of the Subnet the Instance and Security Group will live in | `string` | n/a | yes |
| vpc\_id | ID of the VPC the Instance and Security Group will live in | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| ec2\_id | ID of the instance created |
| ec2\_private\_ip | Private IP of the instance created |
| ec2\_ssh\_key\_name | Key Pair Name attached to the instance |

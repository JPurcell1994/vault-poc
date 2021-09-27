# Vault-Demo 

This is a repo to cover the use of packer and terraform, to spin up a vault-service instance with vault pre-installed on a ubuntu AMI.

## Packer

### Packer Use Case:

Our use case is we want to create an AMI with vault baked in. This will allow us to not have to ssh to a machine, download and install vault everytime we update our AMI. The perk of this is we then own that image, if we need to rebuild our servers it becomes a private image which we can maintain and audit properly. There is no worry that if an ELB spots an unhealthy host, attempts to rebuild our machine with a public AMI that no longer exists, this would cause our application to fall over.

For the use case we are also going to install mysql to show the mysql plugin in action.

We are going to write a packer.json file which contains both our variables and our packer configuration. You can seperate these

```json
{
  "variables": {
    "source_ami_name_prefix": "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20210430",
    "source_ami_owners": "099720109477",
    "image_name": "",
    "instance_type": "",
    "region": "",
    "vpc_id": "",
    "subnet_id": "",
    "ssh_username": "ubuntu"
  },
  "builders": [
    {
      "type": "amazon-ebs",
      "source_ami_filter": {
        "filters": {
          "name": "{{user `source_ami_name_prefix`}}"
        },
        "owners": ["{{user `source_ami_owners`}}"],
        "most_recent": true
      },
      "ami_name": "{{user `image_name`}}",
      "instance_type": "{{user `instance_type`}}",
      "region": "{{user `region`}}",
      "ssh_username": "{{user `ssh_username`}}",
      "vpc_id": "{{user `vpc_id`}}",
      "subnet_id": "{{user `subnet_id`}}",
      "ssh_pty": "true"
    }
  ],
  "provisioners": [{
    "type": "shell",
    "inline": [
      "sleep 30",
      "sudo apt-get update",
      "sudo apt-get install unzip -y",
      "sudo apt install mysql-client-core-8.0",
      "curl -L https://releases.hashicorp.com/vault/1.8.2/vault_1.8.2_linux_amd64.zip -o vault.zip",
      "unzip vault.zip",
      "sudo chown root:root vault",
      "sudo mv vault /usr/local/bin/",
      "rm -f vault.zip"
    ]
  }]
}
```

#### What is Packer Doing?

<details>
<summary>Details</summary>
<br>
We are using an amazon-ebs builder, we are choosing the latest ubuntu image from amazons free tier. We are deploying it in a VPC and Subnet known to us. Packer will generate temporary credentials and we don't need to give it a ssh-key. Our ssh-username will be ubuntu.

In the shell provisioner you can see what we are doing and installing.

We are waiting 30 seconds to allow proper config time, we are then going to do an apt-get update to make sure all our packages are up to date.

Then we install unzip with apt-get, this will be needed to unzip the vault release later.

We then install my-sql for the demo purposes.

After this we download the latest hashicorp vault release zip which as of writing this is 1.8.2.

We unzip this, change ownership, move vault to /usr/local/bin and then clean up the zip file.
</details>

#### Applying Packer:

```shell
packer build packer.json
```

Should provide us with a new AMI image with mysql and vault installed.

We can now move onto the terraform.

## Terraform

We are going to use terraform to spin up our solo vault instance.

We have chosen to take a moduled approach and will be configuring most of our terraform inside of a module.

Inside of our module we are going to split up our terraform files into their respective elements.

The ami.tf
```terraform
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
```

<details>
<summary>Further Explanation</summary>
<br>
This is simply saying, generate a data source looking inside of our own account for an AMI with the prefix provided
If there are multiple, choose the latest.

</details>

Next we have a security.tf where we are going to define the instances security group

```terraform
resource "aws_security_group" "allow_ssh" {
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.security_group_ingress
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.security_group_egress
  }
}
```

<details>
<summary>Further Explanation</summary>
<br>
All this is doing is building a security group in AWS, which has port 22 open for a specific IP (our IP) so we can make a request to the instances port 22 without being denied. At this point we can use our key pair to authenticate to the instance.

</details>

Last we have our ec2.tf

```terraform
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
```
<details>
<summary>Further Explanation</summary>
<br>
At this point we are using the previous AMI image ID found. Giving it a free tier t2.micro for display purposes. Choosing a subnet and VPC the same as chosen in packer.

Because we want to ssh to this instance we need to provide it an ssh key.

vpc_security_group_ids is the output from the security.tf above.

</details>

#### Applying Terraform

To apply the module above we need to create a `module` in terraform with the correct source. You can see this inside of 

`/terraform/vault-demo/instance.tf`

Inside of this directory with the correct variables passed into the module we can then run

```terraform apply```

Which should give us 

`2 to create, 0 to change, 0 to destroy.` 

We can build this and wait for the instance to spin up and become available.

Now we can ssh to the instance with

```terraform
ssh -i ~/.ssh/key-name.pem ubuntu@<IP_ADDR>
```

We will open two seperate terminal connections to the vault server.

# Vault

We have a server with the vault unzipped and moved to /usr/local/bin/ but not configured

We need to create a config.hcl file
```hcl
storage "raft" {
  path    = "./vault/data"
  node_id = "node1"
}

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = "true"
}

disable_mlock = true

api_addr = "http://127.0.0.1:8200"
cluster_addr = "http://127.0.0.1:8201"
```

Create the /vault/data directory

```shell
mkdir -p ./vault/data
```

Now lets start vault

```hcl
vault server -config=config.hcl
```

In other window
```hcl
export VAULT_ADDR='http://127.0.0.1:8200'
vault operator init
```

Copy the unseal keys and initial root token. This can be done automatically through something like AWS KMS.

```hcl
vault operator unseal <key> x3
```

Vault is now unsealed

We now need to authenticate to vault with our root token, lets log into vault.

```shell
vault login <root token>
```

We want to do 3 things, enable database secrets engine in Vault,

```hcl
vault secrets enable database
```

Configure vault with mysql-rds-database-plugin, provide it the correct mysql config

```hcl
vault write database/config/demo-database \
    plugin_name=mysql-rds-database-plugin \
    connection_url="{{username}}:{{password}}@tcp(${rds_endpoint}:3306)/" \
    allowed_roles="demo-role" \
    username=<Username> \
    password=<Password>"
```

Configure a vault role that mape a name in Vault to an SQL statement to create DB credentials
```hcl
vault write database/roles/demo-role \
    db_name=demo-database \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="1h" \
    max_ttl="24h"
```

We can convert this into one shell script. Lets call it, rds-creds.sh

```shell
#!/bin/bash

rds_username=$1
rds_password=$2
rds_endpoint=$3

# Enable Database Secrets Engine
vault secrets enable database

# Configure Vault with the proper plugin and connection information
vault write database/config/demo-database \
    plugin_name=mysql-rds-database-plugin \
    connection_url="{{username}}:{{password}}@tcp(${rds_endpoint}:3306)/" \
    allowed_roles="demo-role" \
    username="${rds_username}" \
    password="${rds_password}"

# Configure a role that maps a name in Vault to an SQL statement to execute to create the database credential
vault write database/roles/demo-role \
    db_name=demo-database \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="1h" \
    max_ttl="24h"
```

When we run this script, we provide it with these 3 pieces of information

```shell
chmod +x rds-creds.sh
./rds-creds.sh <RDS Username> <RDS Password> <RDS endpoint>

Success! Enabled the database secrets engine at: database/
Success! Data written to: database/roles/demo-role
```

With this completed, we can now read some credentials
```shell
vault read database/creds/demo-role
Key                Value
---                -----
lease_id           <Lease ID>
lease_duration     1h
lease_renewable    true
password           <Password>
username           <Username>
```

We can now check these values by running a mysql command with them.

```shell
mysql -h <RDS Endpoint> -u <Username> -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
```

From here we can use MySQL as we wish, but the perk of having vault create us dynamic credentials is we can revoke the leases early if any security concerns are raised. Or we can even restrict the TTL.

If we look above, we can see there is a lease_id, lets copy this and then revoke it.

```shell
vault lease revoke <Lease ID>
```

```shell
All revocation operations queued successfully!
```

If we attempt to run the same command as before

```shell
mysql -h <RDS Endpoint> -u <Username> -p
Enter password:
ERROR 1045 (28000): Access denied for user '<Username>'@'<IP_ADDR>' (using password: YES)
```

Lets generate a new credential,

````shell
vault read database/creds/demo-role
Key                Value
---                -----
lease_id           <New Lease ID>
lease_duration     1h
lease_renewable    true
password           <New Password>
username           <New Username>
````

```shell
mysql -h <RDS Endpoint> -u <New Username> -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
4 rows in set (0.00 sec)
```

We can see that we are easily able to create rds credentials, and then revoke them early if needed, or they will revoke themselves within the lease_duration of 1 hour.
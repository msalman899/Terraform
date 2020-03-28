variable "aws_az" {}
variable "billing_code_tag" { default = "default-billing"}
variable vpc_cidr {}
variable "enable_dns_hostnames" { default = "false" }
variable "custom_tags" { 
    default = { 
        team="default"
    }
}
variable "public_subnet_count" { default = "0"}
variable "private_subnet_count" { default = "0"}

############
## LOCALS
###########

locals {

  env_name = lower(terraform.workspace)

  common_tags = {
	billingcode= var.billing_code_tag
	environment= local.env_name
  }
}

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {default = "us-east-1"}
variable "ami" { default="1234" }
variable "aws_az" {}
variable "key_name" { default="test server"}
variable "private_key_path" {default = "/tmp/key.pem"}
variable "bucket_name_prefix" {}
variable "billing_code_tag" {}
variable vpc_cidr {}
variable "instance_type" {
  type = map(string)
}
variable "subnet_count" {
  type = map(number)
}
variable "instance_count" {
  type = map(number)
}

############
## LOCALS
###########

locals {

  env_name = lower(terraform.workspace)

  common_tags = {
	billingcode= var.billing_code_tag
	environment= local.env_name
  }
  sg_tags = {
	name="${local.env_name}-sg"
  }
  elb_tags = {
	name="${local.env_name}-elb"
  }
  rt_tags = {
	name="${local.env_name}-rt"
  }
  sbn_tags = {
	name="${local.env_name}-sbn"
  }
  s3_tags = {
	name="${local.env_name}-web-bucket"
  }
  s3_bucket_name = "${var.bucket_name_prefix}-${local.env_name}-${random_integer.rand.result}"
}

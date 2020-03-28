variable "bucket_name" {}
variable "billing_code_tag" { default = "default-billing"}
variable "custom_tags" { 
    default = { 
        team="default"
    }
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
  s3_bucket_name = "${var.bucket_name}-${local.env_name}-${random_integer.rand.result}"
}

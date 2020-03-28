
##############
##  MODULES
#############



module "my-vpc" {
  source = "./Modules/VPC/"
  vpc_cidr = var.vpc_cidr[terraform.workspace]
  aws_az=var.aws_az
  #enable_dns_hostnames=""
  public_subnet_count=var.public_subnet_count[terraform.workspace]
  private_subnet_count=var.private_subnet_count[terraform.workspace]
  custom_tags = { 
    team = terraform.workspace
  }
  

}

module "my-s3" {
  source = "./Modules/S3/"
  bucket_name=var.bucket_name
  custom_tags = { 
    team = terraform.workspace
  }

}


##############
## RESOURCES
#############

## insatnces ##

resource "aws_instance" "nginx_server" {
        count = var.instance_count[terraform.workspace]
        #ami = data.aws_ami.aws-linux.id
        ami = var.ami
        subnet_id = module.my-vpc.aws_public_subnet_id[count.index % length(module.my-vpc.aws_public_subnet_id)]
        instance_type = var.instance_type[terraform.workspace]
        key_name = var.key_name
        #security_groups = [aws_security_group.webserver_sg.id]
        #iam_instance_profile = aws_iam_instance_profile.s3access_profile.name

        tags = merge(local.common_tags, {name="${local.env_name}-nginx${count.index+1}"})
        #depends_on = [aws_iam_role.s3access_role,aws_iam_role_policy.allow_s3_all]


}



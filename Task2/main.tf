variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {default = "us-east-1"}
variable "ami" { default="1234" }
variable "key_name" { default="test server"}
variable "instance_type" { default = "t2.micro"}
variable "private_key_path" {default = "/tmp/key.pem"}
variable "vpc_cidr" {}
variable "subnet_cidr" {}


############
## PROVIDERS
###########

provider "aws" {
        access_key = var.aws_access_key
        secret_key = var.aws_secret_key
        region = var.aws_region
}


##############
## Data sources
##############

data "aws_availability_zones" "available" {}

data "aws_ami" "aws-linux" {
  most_recent=true
  owners=["amazon"]

  filter {
        name = "name"
        values = ["amzn-ami-hvm*"]
  }

  filter {
        name = "root-device-type"
        values = ["ebs"]
  }

  filter {
        name = "virtualization-type"
        values = ["hvm"]
  }


}


##############
## RESOURCES
#############

## Networking ##

resource "aws_vpc" "my-vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = "true"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

}

resource "aws_subnet" "my-subnet" {
  cidr_block = var.subnet_cidr
  vpc_id = aws_vpc.my-vpc.id
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[0]
}

## Routing ##

resource "aws_route_table" "my-rtb" {
  vpc_id = aws_vpc.my-vpc.id

  route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "my-rtb_my-subnet" {
  subnet_id = aws_subnet.my-subnet.id
  route_table_id = aws_route_table.my-rtb.id

}


## Security Groups ##

resource "aws_security_group" "webserver_sg" {
  name        = "webserver"
  description = "allow ssh and http traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## Instances ##

resource "aws_instance" "nginx_server" {
        ami = data.aws_ami.aws-linux.id
        subnet_id = aws_subnet.my-subnet.id
        instance_type = var.instance_type
        key_name = var.key_name
        security_groups = [aws_security_group.webserver_sg.id]

        tags = {
          Name = "WebServer"
          Component = "app"
        }

        connection {
        type        = "ssh"
        host        = self.public_ip
        user        = "ec2-user"
        private_key = file(var.private_key_path)

        }


        provisioner "remote-exec" {

                inline = [
                "yum install -y nginx",
                "systemctl start nginx",
                "systemctl enable nginx",
                "echo '<html><head><title>Blue Team Server</title></head><body style=\"background-color:#1F778D\"><p style=\"text-align: center;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:28px;\">Blue Team</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html"
                ]
        }

}

############
# OUTPUT
###########

output "aws_instance_public_dns" {
  value = aws_instance.nginx_server.public_dns
}

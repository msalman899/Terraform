variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {default = "us-east-1"}
variable "ami" { default="1234" }
variable "key_name" { default="test server"}
variable "instance_type" { default = "t2.micro"}
variable "private_key_path" {default = "/tmp/key.pem"}

## PROVIDERS

provider "aws" {
        access_key = var.aws_access_key
        secret_key = var.aws_secret_key
        region = var.aws_region
}

## RESOURCES

resource "aws_default_vpc" "default" {

}

resource "aws_security_group" "webserver_sg" {
  name        = "webserver"
  description = "allow ssh and http traffic"
  vpc_id      = aws_default_vpc.default.id

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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nginx_server" {
        ami = var.ami
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
                "systemctl enable nginx"
                ]
        }

}


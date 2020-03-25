##############
## RESOURCES
#############

## Misc ##

resource "random_integer" "rand" {
 min=10000
 max=99999
}

## Networking ##

resource "aws_vpc" "my-vpc" {
  cidr_block = var.vpc_cidr[terraform.workspace]
  enable_dns_hostnames = "true"
  
  tags = merge(local.common_tags, {name="${local.env_name}-vpc"})
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

}

resource "aws_subnet" "my-subnet" {
  count = var.subnet_count[terraform.workspace]
  cidr_block = cidrsubnet(var.vpc_cidr[terraform.workspace],8,count.index)
  vpc_id = aws_vpc.my-vpc.id
  map_public_ip_on_launch = "true"
  #availability_zone = data.aws_availability_zones.available.names[count.index]
  availability_zone = var.aws_az[count.index % 2]
  tags = merge(local.common_tags, {name="${local.env_name}-sbn${count.index+1}"})
}


## Routing ##

resource "aws_route_table" "my-rtb" {
  vpc_id = aws_vpc.my-vpc.id

  route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, local.rt_tags)
}

resource "aws_route_table_association" "my-rtb_my-subnet" {
  count=var.subnet_count[terraform.workspace]
  subnet_id = aws_subnet.my-subnet[count.index].id
  route_table_id = aws_route_table.my-rtb.id

}


## Security Groups ##

resource "aws_security_group" "elb_sg" {
  name = "webserver_elb"
  vpc_id      = aws_vpc.my-vpc.id

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

  tags = merge(local.common_tags, local.sg_tags)

}

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
    cidr_blocks = [var.vpc_cidr[terraform.workspace],aws_security_group.elb_sg.id]
   #or cidr_blocks = [aws_security_group.elb_sg.id]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags, local.sg_tags)
}

## Load balancer ##

resource "aws_elb" "webserver_elb" {
  name = "${local.env_name}-webserver-elb"
  subnets = aws_subnet.my-subnet[*].id
  security_groups = [aws_security_group.elb_sg.id]
  instances = aws_instance.nginx_server[*].id

  listener {
        instance_port=80
        instance_protocol = "http"
        lb_port = 80
        lb_protocol = "http"

  }
  
  tags = merge(local.common_tags, local.elb_tags)
}


## S3 bucket ##

resource "aws_s3_bucket" "web_bucket" {
  bucket= local.s3_bucket_name
  acl           = "private"
  force_destroy = true

  tags = merge(local.common_tags, local.s3_tags)
}

resource "aws_s3_bucket_object" "website" {
    bucket = aws_s3_bucket.web_bucket.bucket
    key = "/website/index.html"
    source = "./index.html"

}

## iam roles / policies ##

resource "aws_iam_role" "s3access_role" {
  name="${local.env_name}-s3access_role"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "allow_s3_all" {
  name = "${local.env_name}-allow_s3_all"
  role = aws_iam_role.s3access_role.name

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:*"
        ],
        "Effect": "Allow",
        "Resource": [
          "arn:aws:s3:::${local.s3_bucket_name}",
          "arn:aws:s3:::${local.s3_bucket_name}/*"
        ]
      }
    ]
  }
EOF
}

resource "aws_iam_instance_profile" "s3access_profile" {
  name = "${local.env_name}-s3access_profile"
  role = aws_iam_role.s3access_role.name
}

## insatnces ##

resource "aws_instance" "nginx_server" {
        count = var.instance_count[terraform.workspace]
        #ami = data.aws_ami.aws-linux.id
        ami = var.ami
        subnet_id = aws_subnet.my-subnet[count.index % var.subnet_count[terraform.workspace]].id
        instance_type = var.instance_type[terraform.workspace]
        key_name = var.key_name
        security_groups = [aws_security_group.webserver_sg.id]
        iam_instance_profile = aws_iam_instance_profile.s3access_profile.name

        tags = merge(local.common_tags, {name="${local.env_name}-nginx${count.index+1}"})
        depends_on = [aws_iam_role.s3access_role,aws_iam_role_policy.allow_s3_all]

        connection {
        type        = "ssh"
        host        = self.public_ip
        user        = "ec2-user"
        private_key = file(var.private_key_path)

        }

        provisioner "file" {
          content = <<EOF
            /var/log/nginx/*log {
                daily
                rotate 10
                missingok
                compress
                sharedscripts
                postrotate
                endscript
                lastaction
                    INSTANCE_ID=`curl --silent http://169.254.169.254/latest/meta-data/instance-id`
                    sudo /usr/local/bin/s3cmd sync /var/log/nginx/ s3://${aws_s3_bucket.web_bucket.id}/nginx/$INSTANCE_ID/
                endscript
          }
          EOF
          destination = "/home/ec2-user/nginx"
        }

        provisioner "remote-exec" {

                inline = [
                "yum install -y nginx",
                "systemctl start nginx",
                "systemctl enable nginx",
                "sudo cp /home/ec2-user/nginx /etc/logrotate.d/nginx",
                "sudo pip install s3cmd",
                "s3cmd get s3://${aws_s3_bucket.web_bucket.id}/website/index.html /usr/share/nginx/html/index.html",
                "sudo logrotate -f /etc/logrotate.conf"
                ]
        }

}


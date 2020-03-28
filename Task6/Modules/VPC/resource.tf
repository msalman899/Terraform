## Networking ##

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames ? var.enable_dns_hostnames : "true"
  
  tags = merge(local.common_tags, var.custom_tags, {name="${local.env_name}-vpc"})
}

resource "aws_internet_gateway" "igw" {
  count = var.public_subnet_count > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id

}

resource "aws_subnet" "subnet" {
  count = var.public_subnet_count+var.private_subnet_count
  cidr_block = cidrsubnet(var.vpc_cidr,8,count.index)
  vpc_id = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  #availability_zone = data.aws_availability_zones.available.names[count.index]
  availability_zone = var.aws_az[count.index % length(var.aws_az)]
  tags = merge(local.common_tags,var.custom_tags, {name="${local.env_name}-subnet${count.index+1}"} )
}


## Routing ##

resource "aws_route_table" "public-rtb" {
  count = var.public_subnet_count > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = merge(local.common_tags, var.custom_tags,{name="${local.env_name}-public_rtb${count.index+1}"} )
}

resource "aws_route_table" "private-rtb" {
  count = var.private_subnet_count > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, var.custom_tags,{name="${local.env_name}-private-rtb${count.index+1}"} )
}

resource "aws_route_table_association" "public" {
  count = var.public_subnet_count
  subnet_id = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.public-rtb[0].id

}

resource "aws_route_table_association" "private" {
  count = var.private_subnet_count
  subnet_id = aws_subnet.subnet[count.index+var.public_subnet_count].id
  route_table_id = aws_route_table.private-rtb[0].id

}
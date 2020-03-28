ami="ami-1234"
aws_az=["us-east-1a","us_east-1b"]
key_name="nginx server"
bucket_name="dummy123"
billing_code_tag="ACT123456"

vpc_cidr = {
  Dev = "10.0.0.0/16"
  UAT = "10.1.0.0/16"
  Prod = "10.2.0.0/16"
}

instance_type = {
  Dev = "t2.micro"
  UAT = "t2.small"
  Prod = "t2.medium"
}

public_subnet_count = {
  Dev = 1
  UAT = 2
  Prod = 3
}

private_subnet_count = {
  Dev = 2
  UAT = 3
  Prod = 4
}

instance_count = {
  Dev = 2
  UAT = 4
  Prod = 6
}

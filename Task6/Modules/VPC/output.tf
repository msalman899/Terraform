############
# OUTPUT
###########

output "aws_vpc_id" {
  value = aws_vpc.vpc.id
}

output "aws_public_subnet_id" {
  value = aws_route_table_association.public[*].subnet_id
}

output "aws_private_subnet_id" {
  value = aws_route_table_association.private[*].subnet_id
}

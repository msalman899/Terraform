############
# OUTPUT
###########

output "aws_elb_public_dns" {
  value = aws_elb.webserver_elb.dns_name
}
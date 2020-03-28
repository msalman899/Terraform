## S3 bucket ##

resource "random_integer" "rand" {
 min=10000
 max=99999
} 

resource "aws_s3_bucket" "web_bucket" {
  bucket= local.s3_bucket_name
  acl           = "private"
  force_destroy = true

  tags = merge(local.common_tags, var.custom_tags)
}

resource "aws_s3_bucket_object" "website" {
    bucket = aws_s3_bucket.web_bucket.bucket
    key = "/website/index.html"
    source = "./index.html"

} 
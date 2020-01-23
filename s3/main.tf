resource "aws_s3_bucket" "b" {
  bucket = "asd"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

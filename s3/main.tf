resource "aws_s3_bucket" "b" {
  bucket = "20200123-test-bucket"
  acl    = "private"

  tags = {
    Name        = "20200123-test-bucket"
  }
}

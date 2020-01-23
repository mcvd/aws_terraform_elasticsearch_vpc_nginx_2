resource "aws_s3_bucket" "default" {
  bucket = "20200123-0924-danilo-test-bucket"
  acl    = "private"

  tags = {
    Name        = "20200123-0924-danilo-test-bucket"
  }
}

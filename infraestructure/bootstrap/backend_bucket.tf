resource "aws_s3_bucket" "b" {
  bucket = "terraform-state-lucas"

  tags = {
    Name        = "Tfstate"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}
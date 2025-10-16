resource "aws_s3_bucket" "react_app" {
  bucket = "gig-diary-react-app-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_website_configuration" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.react_app.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.react_app]
}
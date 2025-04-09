# create s3 bucket
resource "aws_s3_bucket" "web" {
  bucket = var.bucketname
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.web.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.web.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.web.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "site" {
  depends_on = [
    aws_s3_bucket_ownership_controls.site,  
    aws_s3_bucket_public_access_block.site 
  ]

  bucket = aws_s3_bucket.web.id
  acl    = "public-read"
}

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.web.id
  key = "index.html"
  source = "index.html"
  acl = "public-read"
  content_type = "text/html"
}

resource "aws_s3_object" "error" {
  bucket = aws_s3_bucket.web.id
  key = "error.html"
  source = "error.html"
  acl = "public-read"
  content_type = "text/html"
}

resource "aws_s3_object" "images" {
  for_each = { for file in local.image_files : file => file }

  bucket = aws_s3_bucket.web.bucket
  key    = "images/${each.key}"
  source = "${path.module}/images/${each.key}"
  etag   = filemd5("${path.module}/images/${each.key}")

  content_type = lookup(
    {
      png  = "image/png"
      jpg  = "image/jpeg"
      jpeg = "image/jpeg"
    },
    substr(each.key, length(each.key) - 2, 3),
    "application/octet-stream"
  )

  acl = "public-read"
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.web.id
  index_document {
    suffix = "index.html"
  }

  error_document {
    key =  "error.html"
  }

  depends_on = [ aws_s3_bucket_acl.site ]
}

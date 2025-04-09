# 1. Основной бакет
resource "aws_s3_bucket" "web" {
  bucket = var.bucketname
  force_destroy = true  # Для удобства разработки (можно удалить в продакшене)
}

# 2. Настройка владения объектами (полное отключение ACL)
resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.web.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }

  # Явно зависит от создания бакета
  depends_on = [aws_s3_bucket.web]
}

# 3. Настройка публичного доступа
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.web.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  depends_on = [aws_s3_bucket.web]
}

# 4. Политика доступа (вместо ACL)
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

  depends_on = [
    aws_s3_bucket_ownership_controls.site,
    aws_s3_bucket_public_access_block.site
  ]
}

# 5. Конфигурация веб-сайта
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.web.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

# 6. Загрузка файлов (без ACL!)
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.web.id
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"

  depends_on = [aws_s3_bucket_policy.site]
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.web.id
  key          = "error.html"
  source       = "error.html"
  content_type = "text/html"
}

resource "aws_s3_object" "images" {
  for_each = fileset("${path.module}/images", "*.{png,jpg,jpeg}")

  bucket       = aws_s3_bucket.web.id
  key          = "images/${each.value}"
  source       = "${path.module}/images/${each.value}"
  content_type = lookup({
    png  = "image/png",
    jpg  = "image/jpeg",
    jpeg = "image/jpeg"
  }, split(".", each.value)[1], "application/octet-stream")
}

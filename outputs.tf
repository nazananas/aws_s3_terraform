output "website_url" {
  description = "URL of the S3 static website"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.web.arn
}

output "s3_bucket_domain" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.web.bucket_domain_name
}
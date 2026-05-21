output "bucket_name" {
  value = aws_s3_bucket.static_site.bucket
}

output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}

output "bucket_arn" {
  value = aws_s3_bucket.static_site.arn
}

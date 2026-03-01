output "cloudfront_domain_name" {
  value       = module.cloudfront.cloudfront_distribution_domain_name
  description = "Domain name of the CloudFront distribution"
}

output "s3_bucket_name" {
  value       = module.s3_bucket.s3_bucket_id
  description = "Name of the S3 bucket for static files"
}

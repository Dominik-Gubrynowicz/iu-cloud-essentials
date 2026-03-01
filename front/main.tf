data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "iu-poc-tf-state"
    key    = "network/terraform.tfstate"
    region = "eu-west-1"
  }
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.10"

  bucket = "${var.company_name}-${var.environment}-${var.bucket_name}"

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  versioning = {
    enabled = true
  }
}

locals {
  s3_origin_id  = "S3-${module.s3_bucket.s3_bucket_id}"
  alb_origin_id = "ALB-ECS-Cluster"
}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "${var.company_name}-${var.environment}-s3-cloudfront-oac"
  description                       = "OAC for S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 6.4"

  comment             = "CloudFront for ${var.company_name} ${var.environment}"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  retain_on_delete    = false
  wait_for_deployment = false
  default_root_object = "index.html"

  viewer_certificate = {
    cloudfront_default_certificate = true
  }

  origin = {
    s3_static = {
      domain_name              = module.s3_bucket.s3_bucket_bucket_regional_domain_name
      origin_id                = local.s3_origin_id
      origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    }

    alb_api = {
      domain_name = data.terraform_remote_state.network.outputs.alb_dns_name
      origin_id   = local.alb_origin_id
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    use_forwarded_values = false
    cache_policy_id      = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  ordered_cache_behavior = [
    {
      path_pattern           = "/api/*"
      target_origin_id       = local.alb_origin_id
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true

      use_forwarded_values     = false
      cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
    }
  ]
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

# Allow CloudFront to read from S3
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_bucket.s3_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cloudfront.cloudfront_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = module.s3_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_s3_object" "index_html" {
  bucket       = module.s3_bucket.s3_bucket_id
  key          = "index.html"
  source       = "${path.module}/src/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/src/index.html")
}

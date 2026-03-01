variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-west-1"
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket for static files"
  default     = "ecobuy-ecommerce-static-files"
}

variable "company_name" {
  type        = string
  description = "Company name for resource prefixing"
  default     = "ecobuy"
}

variable "environment" {
  type        = string
  description = "Environment name for resource prefixing"
  default     = "poc"
}

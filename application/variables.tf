variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-west-1"
}

variable "image_tag" {
  type        = string
  description = "Tag of the nginx image to deploy"
  default     = "latest"
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

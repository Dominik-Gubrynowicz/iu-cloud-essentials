terraform {
  backend "s3" {
    bucket       = "iu-poc-tf-state"
    key          = "network/terraform.tfstate"
    region       = "eu-west-1" # Or your desired region
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

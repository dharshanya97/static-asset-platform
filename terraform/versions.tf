terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Stretch goal: remote state. Create the bucket + lock table first, then uncomment.
  # backend "s3" {
  #   bucket         = "my-tfstate-bucket"
  #   key            = "static-assets/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "tf-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region
}

# CloudFront-scoped resources (ACM cert, WAF, CloudFront metrics/alarms) must live in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

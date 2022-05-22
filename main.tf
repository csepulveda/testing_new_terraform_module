terraform {
  backend "s3" {
    bucket = "dev-terraform-79characters"
    key    = "terraform-statefile"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}
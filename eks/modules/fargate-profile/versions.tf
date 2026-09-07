terraform {
  required_version = ">= 1.15.4, < 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.52.0"
    }
  }
}
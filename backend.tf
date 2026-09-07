terraform {
  backend "s3" {
    region = "ap-southeast-1"
    key = var.key
    bucket = "tf-backend-agency-devops-ap"
  }
}
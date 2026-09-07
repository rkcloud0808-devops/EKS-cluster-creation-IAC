terraform {
  required_version = ">= 1.15.4, < 1.16.0"

  required_providers {
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.4.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.3.0"
    }
  }
}
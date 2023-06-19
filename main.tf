terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.0"
    }
    ocm = {
      version = ">=1.0.1"
      source  = "terraform.local/local/ocm"
    }
  }
}

provider "ocm" {
  token = var.token
  url   = var.url
}


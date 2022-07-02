

terraform {
  
  required_version = "= 1.2.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.60.0, <= 3.69.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
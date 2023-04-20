terraform {
  required_version = "1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.28"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
  }
}

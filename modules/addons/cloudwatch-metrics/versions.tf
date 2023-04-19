terraform {
  required_version = "1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.28"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4.1"
    }
  }
}

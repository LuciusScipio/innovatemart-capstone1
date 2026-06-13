terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
  #backend "s3" {
    #bucket         = "bedrock-assets-ALT-SOE-25-3343"
    #key            = "eks/project-bedrock/terraform.tfstate"
    #region         = "us-east-1"
    
  #}
}

provider "aws" {
  region = "us-east-1"
}


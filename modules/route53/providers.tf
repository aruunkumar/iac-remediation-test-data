# Provider configuration for Route53 module
# Route53 query logging requires resources in us-east-1 region

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
      configuration_aliases = [
        aws.us-east-1
      ]
    }
  }
}

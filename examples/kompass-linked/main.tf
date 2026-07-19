terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    zesty = {
      source  = "zesty-co/zesty"
      version = "~> 0.3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "zesty" {}

module "zesty_aws_account" {
  source  = "zesty-co/zesty-account/aws"
  version = "~> 0.1"

  account_type = "linked"

  kompass = {}
}

output "kompass_values_yaml" {
  value     = module.zesty_aws_account.kompass_values_yaml
  sensitive = true
}

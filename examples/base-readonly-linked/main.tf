provider "aws" {
  region = "us-east-1"
}

provider "zesty" {}

module "zesty_aws_account" {
  source  = "zesty-co/zesty-account/aws"
  version = "~> 0.1"

  account_type = "linked"
}

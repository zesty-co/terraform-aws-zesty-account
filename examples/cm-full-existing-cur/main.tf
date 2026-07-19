provider "aws" {
  region = "us-east-1"
}

provider "zesty" {}

module "zesty_aws_account" {
  source  = "zesty-co/zesty-account/aws"
  version = "~> 0.1"

  account_type = "management"

  cm = {}

  cur = {
    mode        = "existing"
    type        = "cur_v2"
    s3_bucket   = "customer-cur-bucket"
    export_name = "customer-cur-export"
  }
}

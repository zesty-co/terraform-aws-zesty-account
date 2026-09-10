terraform {
  required_version = ">= 1.5"
  required_providers {
    aws   = { source = "hashicorp/aws", version = "~> 6.0, != 6.57.0" }
    zesty = { source = "zesty-co/zesty", version = "~> 0.3.0" }
  }
}
variable "cluster_name" { type = string }
variable "region" { type = string }
provider "aws" { region = var.region }
provider "zesty" {}

# Use one account module per AWS account. If an existing Terraform configuration
# already owns the account, consume its sensitive values output instead.
module "zesty_account" {
  source       = "../.."
  account_type = "linked"
  kompass      = {}
}
module "kompass_iam" {
  source                   = "../../modules/kompass-cluster-iam"
  pod_identity_enabled     = true
  cluster_name             = var.cluster_name
  insights_agent_role_name = "ZestyInsightsAgent-${var.cluster_name}"
}
output "kompass_values_yaml" {
  value     = module.zesty_account.kompass_values_yaml
  sensitive = true
}
output "kompass_iam_values_yaml" {
  value     = module.kompass_iam.helm_values_yaml
  sensitive = true
}

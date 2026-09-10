terraform {
  required_providers {
    aws  = { source = "hashicorp/aws", version = "~> 6.0, != 6.57.0" }
    helm = { source = "hashicorp/helm", version = "~> 2.17" }
  }
}
variable "region" { type = string }
variable "cluster_name" { type = string }
variable "kube_context" { type = string }
variable "account_values_file" { type = string }
variable "chart_version" { type = string }
provider "aws" { region = var.region }
provider "helm" {
  kubernetes {
    config_path    = pathexpand("~/.kube/config")
    config_context = var.kube_context
  }
}
module "kompass_iam" {
  source                   = "../../modules/kompass-cluster-iam"
  pod_identity_enabled     = true
  cluster_name             = var.cluster_name
  insights_agent_role_name = "ZestyInsightsAgent-${var.cluster_name}"
}
resource "helm_release" "kompass" {
  name             = "kompass"
  repository       = "https://zesty-co.github.io/kompass"
  chart            = "kompass"
  version          = var.chart_version
  namespace        = "zesty-system"
  create_namespace = true
  wait             = false
  values           = concat([file(var.account_values_file)], module.kompass_iam.helm_values)
}

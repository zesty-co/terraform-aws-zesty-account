terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    zesty = {
      source  = "zesty-co/zesty"
      version = "~> 0.3.0"
    }
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster to install Kompass into."
  type        = string
}

variable "region" {
  description = "AWS region for the account and EKS cluster."
  type        = string
  default     = "us-east-1"
}

provider "aws" {
  region = var.region
}

provider "zesty" {}

data "aws_eks_cluster" "target" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "target" {
  name = var.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.target.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.target.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.target.token
  }
}

module "zesty_aws_account" {
  source  = "zesty-co/zesty-account/aws"
  version = "~> 0.1"

  account_type = "linked"

  kompass = {}

  create_values_local_file = false
}

module "kompass_cluster" {
  source  = "zesty-co/zesty-account/aws//modules/kompass-cluster"
  version = "~> 0.1"

  kompass_values_yaml = module.zesty_aws_account.kompass_values_yaml

  pod_identity_enabled     = true
  cluster_name             = var.cluster_name
  insights_agent_role_name = "ZestyInsightsAgent-${var.cluster_name}"
}

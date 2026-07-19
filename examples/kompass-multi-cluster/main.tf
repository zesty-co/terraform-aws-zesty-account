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

variable "region" {
  description = "AWS region for the account and EKS clusters."
  type        = string
  default     = "us-east-1"
}

variable "prod_cluster_name" {
  description = "Name of the production EKS cluster to install Kompass into."
  type        = string
}

variable "dev_cluster_name" {
  description = "Name of the development EKS cluster to install Kompass into."
  type        = string
}

provider "aws" {
  region = var.region
}

provider "zesty" {}

data "aws_eks_cluster" "prod" {
  name = var.prod_cluster_name
}

data "aws_eks_cluster_auth" "prod" {
  name = data.aws_eks_cluster.prod.name
}

data "aws_eks_cluster" "dev" {
  name = var.dev_cluster_name
}

data "aws_eks_cluster_auth" "dev" {
  name = data.aws_eks_cluster.dev.name
}

provider "helm" {
  alias = "prod"

  kubernetes {
    host                   = data.aws_eks_cluster.prod.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.prod.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.prod.token
  }
}

provider "helm" {
  alias = "dev"

  kubernetes {
    host                   = data.aws_eks_cluster.dev.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.dev.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.dev.token
  }
}

module "zesty_aws_account" {
  source  = "zesty-co/zesty-account/aws"
  version = "~> 0.1"

  account_type = "linked"

  kompass = {}

  create_values_local_file = false
}

module "kompass_cluster_prod" {
  source  = "zesty-co/zesty-account/aws//modules/kompass-cluster"
  version = "~> 0.1"

  providers = {
    helm = helm.prod
  }

  kompass_values_yaml = module.zesty_aws_account.kompass_values_yaml

  pod_identity_enabled     = true
  cluster_name             = var.prod_cluster_name
  insights_agent_role_name = "ZestyInsightsAgent-${var.prod_cluster_name}"
}

module "kompass_cluster_dev" {
  source  = "zesty-co/zesty-account/aws//modules/kompass-cluster"
  version = "~> 0.1"

  providers = {
    helm = helm.dev
  }

  kompass_values_yaml = module.zesty_aws_account.kompass_values_yaml

  pod_identity_enabled     = true
  cluster_name             = var.dev_cluster_name
  insights_agent_role_name = "ZestyInsightsAgent-${var.dev_cluster_name}"
}

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

variable "management_region" {
  description = "AWS region used by the management account provider."
  type        = string
  default     = "us-east-1"
}

variable "linked_account_region" {
  description = "AWS region used by the linked account provider."
  type        = string
  default     = "us-east-1"
}

variable "cluster_region" {
  description = "AWS region where the linked account EKS cluster runs."
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the linked account EKS cluster to install Kompass into."
  type        = string
}

provider "aws" {
  alias  = "management"
  region = var.management_region
}

provider "aws" {
  alias  = "linked_account"
  region = var.linked_account_region
}

provider "aws" {
  alias  = "linked_cluster"
  region = var.cluster_region
}

provider "zesty" {}

module "cm_management_account" {
  source  = "zesty-co/zesty-account/aws"
  version = "~> 0.1"

  providers = {
    aws = aws.management
  }

  account_type = "management"

  cm = {}
}

module "kompass_linked_account" {
  source  = "zesty-co/zesty-account/aws"
  version = "~> 0.1"

  providers = {
    aws = aws.linked_account
  }

  account_type = "linked"

  kompass = {}

  create_values_local_file = false
}

data "aws_eks_cluster" "linked" {
  provider = aws.linked_cluster

  name = var.cluster_name
}

data "aws_eks_cluster_auth" "linked" {
  provider = aws.linked_cluster

  name = data.aws_eks_cluster.linked.name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.linked.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.linked.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.linked.token
  }
}

module "kompass_cluster" {
  source  = "zesty-co/zesty-account/aws//modules/kompass-cluster"
  version = "~> 0.1"

  kompass_values_yaml = module.kompass_linked_account.kompass_values_yaml
}

output "cm_management_role_arn" {
  value = module.cm_management_account.role_arn
}

output "kompass_linked_role_arn" {
  value = module.kompass_linked_account.role_arn
}

output "kompass_cluster_namespace" {
  value = module.kompass_cluster.namespace
}

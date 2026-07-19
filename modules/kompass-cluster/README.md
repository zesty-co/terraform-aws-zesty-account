# Kompass Cluster Module

Installs the Kompass Helm chart into one EKS cluster.

Use this module after the AWS account has been onboarded with the root
`zesty-account` module and Kompass is enabled.

## How It Selects A Cluster

This module uses the caller's Helm provider. It installs Kompass into whichever
EKS cluster the Helm provider points to.

```hcl
data "aws_eks_cluster" "target" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "target" {
  name = data.aws_eks_cluster.target.name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.target.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.target.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.target.token
  }
}

module "kompass_cluster" {
  source  = "zesty-co/zesty-account/aws//modules/kompass-cluster"
  version = "~> 0.1"

  kompass_values_yaml = module.zesty_account.kompass_values_yaml
}
```

## Pod Identity

For EKS Pod Identity, let the module create the IAM role and associations:

```hcl
module "kompass_cluster" {
  source  = "zesty-co/zesty-account/aws//modules/kompass-cluster"
  version = "~> 0.1"

  kompass_values_yaml = module.zesty_account.kompass_values_yaml

  pod_identity_enabled     = true
  cluster_name             = var.cluster_name
  insights_agent_role_name = "ZestyInsightsAgent-${var.cluster_name}"
}
```

The EKS `eks-pod-identity-agent` add-on must be installed in the cluster before
creating Pod Identity associations.

## Multiple Clusters

Call this module once per EKS cluster and pass a different Helm provider alias
to each module block.

```hcl
module "kompass_cluster_prod" {
  source  = "zesty-co/zesty-account/aws//modules/kompass-cluster"
  version = "~> 0.1"

  providers = {
    helm = helm.prod
  }

  kompass_values_yaml = module.zesty_account.kompass_values_yaml
}

module "kompass_cluster_dev" {
  source  = "zesty-co/zesty-account/aws//modules/kompass-cluster"
  version = "~> 0.1"

  providers = {
    helm = helm.dev
  }

  kompass_values_yaml = module.zesty_account.kompass_values_yaml
}
```

See `examples/kompass-multi-cluster` for the full provider-alias example.

## Notes

- The module uses the HashiCorp Helm provider `~> 2.17`.
- cert-manager is handled by the Kompass Helm chart.
- `wait` defaults to `false` because the Kompass chart creates some resources
  through Helm hooks after the main release is created.
- `storage_class_name` is optional. Use it only when the cluster requires a
  specific Kubernetes StorageClass.

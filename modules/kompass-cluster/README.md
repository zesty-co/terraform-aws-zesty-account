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

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.target.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.target.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command = "aws"
      args = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.region]
    }
  }
}

module "kompass_cluster" {
  source  = "zesty-co/zesty-account/aws//modules/kompass-cluster"
  version = "~> 0.1.1"

  kompass_values_yaml = module.zesty_account.kompass_values_yaml
}
```

## Pod Identity

For EKS Pod Identity, let the module create the IAM role and associations:

```hcl
module "kompass_cluster" {
  source  = "zesty-co/zesty-account/aws//modules/kompass-cluster"
  version = "~> 0.1.1"

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
  version = "~> 0.1.1"

  providers = {
    helm = helm.prod
  }

  kompass_values_yaml = module.zesty_account.kompass_values_yaml
}

module "kompass_cluster_dev" {
  source  = "zesty-co/zesty-account/aws//modules/kompass-cluster"
  version = "~> 0.1.1"

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

## Optional wrapper and readiness

For Helm CLI/GitOps or a caller-owned Helm resource, use the AWS-only
[kompass-cluster-iam](../kompass-cluster-iam) module. Existing wrapper users retain
resource ownership through the included `moved` declarations. See
[migration](../../docs/helm-migration.md) before changing ownership.

`wait = false` accommodates post-install certificate hooks; it does not certify
pod readiness. Check Deployments, StatefulSets, and bound PVCs after installation.
Pin `chart_version` in production. The Helm provider remains pinned to 2.17 until
3.x is separately validated against the chart's hooks.

`extra_values` is applied last and may intentionally override generated fields.
Preserve account credentials and match the IAM module's ServiceAccount names.
See [storage](../../docs/storage.md) for default/override behavior.

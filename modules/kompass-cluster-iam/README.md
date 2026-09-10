# Kompass cluster IAM

Creates the optional pod IAM role and IRSA trust or EKS Pod Identity associations.
It requires only the AWS provider, with no Helm/Kubernetes provider or cluster API
connection. Use it with Helm CLI, GitOps, or a customer-owned `helm_release`.
The account onboarding role and the pod identity role have different purposes.

## Pod Identity

```hcl
module "kompass_iam" {
  source = "../../modules/kompass-cluster-iam"

  pod_identity_enabled     = true
  cluster_name             = var.cluster_name
  insights_agent_role_name = "ZestyInsightsAgent-${var.cluster_name}"
}
```

The EKS Pod Identity Agent add-on must already be installed. The AWS provider must
use the cluster's account and region. Associations cover both Insights and its
self-monitoring ServiceAccount in `zesty-system` (override `namespace` if needed).

For IRSA use `irsa_enabled = true`, an existing `oidc_provider_arn`, and a unique
`insights_agent_role_name`. The modes are mutually exclusive. If identity is
managed externally, omit this module or leave both modes disabled.

Apply `helm_values` (an ordered list) after account values for `helm_release`.
For Helm CLI, use `helm_values_yaml` as one separate values file. The output adds
IRSA annotations where needed and optional management-role configuration; it
does not replace the generated account values or contain Kubernetes credentials.

`service_account_name` and `self_monitoring_service_account_name` describe the
names already rendered by the chart. Changing these inputs alone does not rename
chart ServiceAccounts; configure matching chart name overrides as appropriate.

For cross-account billing, provide `management_role_arn` and
`management_role_external_id`. The management-account role must also trust the
pod role. The account module's optional organization trust can provide this for
accounts in the same AWS Organization; never enable it for standalone accounts.

See [Helm CLI example](../../examples/kompass-helm-cli) and
[migration notes](../../docs/helm-migration.md).

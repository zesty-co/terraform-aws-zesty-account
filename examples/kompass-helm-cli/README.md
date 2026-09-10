# Terraform account + Helm CLI

This example uses modules from this checkout, including the new AWS-only IAM
module. Published `0.1.1` does not yet include that submodule.

The CLI path was tested with Helm 3.22.0.

Prerequisites: an existing EKS cluster, AWS/Zesty credentials (`ZESTY_API_TOKEN`),
EBS CSI or another suitable storage provisioner, a default StorageClass, and the
EKS Pod Identity Agent add-on. Install in an existing account only through its
current Terraform owner; do not create a second account module/state.

```sh
terraform init
terraform apply -var='cluster_name=my-cluster' -var='region=us-east-1'

# Run in a private directory. These files contain credentials; do not commit them.
umask 077
terraform output -raw kompass_values_yaml > values.yaml
terraform output -raw kompass_iam_values_yaml > iam-values.yaml
chmod 600 values.yaml iam-values.yaml

aws eks update-kubeconfig --name my-cluster --region us-east-1 --alias my-cluster
helm upgrade --install kompass kompass \
  --repo https://zesty-co.github.io/kompass --version 0.3.16 \
  --namespace zesty-system --create-namespace --kube-context my-cluster \
  -f values.yaml -f iam-values.yaml
```

`0.3.16` is an explicit published example pin, not a promise to select the newest
chart automatically. Use a tested chart version; the accompanying chart fix will
ship separately as `0.3.17`. The chart's post-install certificate hooks are why
this example does not add `--wait`. Check deployments/statefulsets and PVCs after
Helm completes; a deployed Helm release alone does not establish readiness.

```sh
kubectl --context my-cluster -n zesty-system get pods,pvc
kubectl --context my-cluster -n zesty-system rollout status deployment/kompass-insights --timeout=10m
```

The chart enables cert-manager by default. Only if an existing installation
already supplies it, put `cert-manager: {enabled: false}` in `cluster-values.yaml`
and append `-f cluster-values.yaml`. Keep generated values first, IAM values
second, cluster overrides last. Helm merges these maps; do not replace the entire
`kompass-insights` map using a shallow Terraform `merge`.

No StorageClass input is needed when generated values omit storage choices and
the cluster has a suitable default. Older onboarding backends may still generate
`ebs-sc`. Use the explicit overlays in [storage configuration](../../docs/storage.md)
until the backend fix is deployed; switching the Helm installer alone does not
remove those values.

For GitOps, deliver the same ordered values through your encrypted secret workflow.
Do not commit plaintext generated values. Confirm your controller's hook and CRD
handling for this chart; the CLI example is not an ArgoCD compatibility test.

Terraform owns IAM/account resources; Helm owns the release. Uninstall the release
before destroying this example's pod IAM. Do not destroy shared account resources
while other clusters still use them.

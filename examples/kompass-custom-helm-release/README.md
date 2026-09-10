# Customer-owned helm_release

Use generated account values from their existing Terraform owner. Supply the
account values file, an explicit chart version, AWS region/cluster name, and the
matching kubeconfig context. This example uses the new IAM module from this
checkout. It keeps the Helm resource in the caller so customers can control its
full settings. See the [Helm CLI example](../kompass-helm-cli) for prerequisites,
value ordering, storage, cert-manager, readiness, and credential handling.

variable "kompass_values_yaml" {
  description = "Kompass Helm values YAML content from the account onboarding module output."
  type        = string
  sensitive   = true
}

variable "release_name" {
  description = "Helm release name."
  type        = string
  default     = "kompass"
}

variable "repository" {
  description = "Kompass Helm chart repository."
  type        = string
  default     = "https://zesty-co.github.io/kompass"
}

variable "chart" {
  description = "Kompass Helm chart name."
  type        = string
  default     = "kompass"
}

variable "chart_version" {
  description = "Optional Kompass Helm chart version. Null uses the latest version allowed by the Helm provider."
  type        = string
  default     = null
}

variable "namespace" {
  description = "Kubernetes namespace for Kompass."
  type        = string
  default     = "zesty-system"
}

variable "create_namespace" {
  description = "Whether Helm should create the namespace."
  type        = bool
  default     = true
}

variable "cleanup_on_fail" {
  description = "Whether Helm should delete newly-created resources when installation fails."
  type        = bool
  default     = true
}

variable "wait" {
  description = "Whether Helm should wait for resources to become ready."
  type        = bool
  default     = false
}

variable "timeout" {
  description = "Time in seconds to wait for Helm operations."
  type        = number
  default     = 300
}

variable "storage_class_name" {
  description = "Optional Kubernetes StorageClass name for Kompass PVCs. Null keeps the generated values as-is."
  type        = string
  default     = null
}

variable "extra_values" {
  description = "Additional Helm values YAML documents applied after the generated Kompass values."
  type        = list(string)
  default     = []
}

# ── insights-agent IAM role ────────────────────────────────────────────────────

variable "irsa_enabled" {
  description = "Create an IAM role with OIDC federated trust for IRSA (IAM Roles for Service Accounts). Mutually exclusive with pod_identity_enabled."
  type        = bool
  default     = false
}

variable "pod_identity_enabled" {
  description = "Create an IAM role with pods.eks.amazonaws.com trust for EKS Pod Identity. Mutually exclusive with irsa_enabled."
  type        = bool
  default     = false
}

variable "insights_agent_role_name" {
  description = "Name of the IAM role to create for the insights-agent pod. Required when irsa_enabled or pod_identity_enabled is true. Must be unique per cluster (e.g. ZestyInsightsAgent-my-cluster)."
  type        = string
  default     = null
}

variable "service_account_name" {
  description = "Kubernetes ServiceAccount name used by the insights-agent pod. Must match the ServiceAccount defined in the Kompass Helm chart."
  type        = string
  default     = "kompass-insights-sa"
}

variable "self_monitoring_service_account_name" {
  description = "Kubernetes ServiceAccount name used by the insights-agent self-monitoring pod. Must match the ServiceAccount defined in the Kompass Helm chart."
  type        = string
  default     = "kompass-insights-self-monitoring-sa"
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for the EKS cluster. Required when irsa_enabled is true. Example: arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/XXXX"
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "EKS cluster name. Required when pod_identity_enabled is true and create_pod_identity_association is true."
  type        = string
  default     = null
}

variable "create_pod_identity_association" {
  description = "Create an aws_eks_pod_identity_association that binds the IAM role to the cluster, namespace, and ServiceAccount. Only applies when pod_identity_enabled is true. Set to false if the eks-pod-identity-agent addon is not yet installed or the association is managed separately."
  type        = bool
  default     = true
}

# ── Management account cross-account role ─────────────────────────────────────

variable "management_role_arn" {
  description = "ARN of the IAM role in the management/payer account the insights-agent will assume for CUR/Athena/Glue access. Created by the terraform-aws-zesty-account module (role_arn output). When null, cross-account CUR access is disabled."
  type        = string
  default     = null
}

variable "management_role_external_id" {
  description = "External ID the insights-agent must pass when assuming the management role. Use the external_id output of the terraform-aws-zesty-account module. When empty, no ExternalId is sent."
  type        = string
  default     = ""
  sensitive   = true
}

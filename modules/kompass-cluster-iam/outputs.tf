output "insights_agent_role_arn" {
  description = "Pod IAM role ARN, or null when role creation is disabled."
  value       = local.iam_enabled ? aws_iam_role.insights_agent[0].arn : null
}

output "helm_values" {
  description = "Ordered YAML overlays for the Kompass chart. Apply after account values, before customer overrides."
  value       = compact([local.irsa_values, local.management_role_values])
  sensitive   = true
  depends_on = [
    aws_iam_role_policy.insights_agent,
    aws_eks_pod_identity_association.insights_agent,
    aws_eks_pod_identity_association.insights_agent_self_monitoring,
    terraform_data.validation,
  ]
}

output "helm_values_yaml" {
  description = "Single YAML overlay for Helm CLI/GitOps. Merge only the distinct IAM-owned fields; account values remain a separate document."
  value = yamlencode({
    "kompass-insights" = merge(
      try(yamldecode(local.irsa_values)["kompass-insights"], {}),
      try(yamldecode(local.management_role_values)["kompass-insights"], {})
    )
  })
  sensitive = true
  depends_on = [
    aws_iam_role_policy.insights_agent,
    aws_eks_pod_identity_association.insights_agent,
    aws_eks_pod_identity_association.insights_agent_self_monitoring,
    terraform_data.validation,
  ]
}

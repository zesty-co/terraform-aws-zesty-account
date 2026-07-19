output "release_name" {
  description = "Kompass Helm release name."
  value       = helm_release.kompass.name
}

output "namespace" {
  description = "Kompass namespace."
  value       = helm_release.kompass.namespace
}

output "status" {
  description = "Kompass Helm release status."
  value       = helm_release.kompass.status
}

output "insights_agent_role_arn" {
  description = "ARN of the insights-agent IAM role. Null when neither irsa_enabled nor pod_identity_enabled is true."
  value       = local.iam_enabled ? aws_iam_role.insights_agent[0].arn : null
}

output "enabled" {
  description = "Whether CM is requested."
  value       = var.enabled
}

output "product_specs" {
  description = "Zesty product payload fragments for CM."
  value       = local.product_specs
}

output "iam_policy_statements" {
  description = "IAM policy statements needed for CM automation."
  value       = local.iam_policy_statements
}

output "requirements" {
  description = "Account/resource requirements for CM."
  value = {
    requires_management_account = var.enabled
    requires_cur                = var.enabled
    requires_athena             = false
  }
}

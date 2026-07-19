output "enabled" {
  description = "Whether Kompass is requested."
  value       = var.enabled
}

output "management_mode" {
  description = "Whether Kompass is running in management-account mode."
  value       = local.management_mode
}

output "product_specs" {
  description = "Zesty product payload fragments for Kompass."
  value       = local.product_specs
}

output "iam_policy_statements" {
  description = "IAM policy statements needed for management-account Kompass."
  value       = local.iam_policy_statements
}

output "requirements" {
  description = "Account/resource requirements for Kompass."
  value = {
    requires_management_account = false
    requires_cur                = local.management_mode
    requires_athena             = local.management_mode
  }
}

output "account_id" {
  description = "AWS account ID onboarded to Zesty."
  value       = data.aws_caller_identity.current.account_id
}

output "account_type" {
  description = "AWS account type configured for this module."
  value       = local.account_type
}

output "role_arn" {
  description = "IAM role ARN assumed by Zesty."
  value       = aws_iam_role.zesty_iam_role.arn
}

output "external_id" {
  description = "External ID configured in the IAM role trust policy."
  value       = random_uuid.zesty_external_id.result
  sensitive   = true
}

output "cur_bucket" {
  description = "CUR S3 bucket name when CUR is configured."
  value       = local.cur_bucket_name
}

output "cur_export_name" {
  description = "CUR report/export name sent to Zesty."
  value       = local.requires_cur ? local.cur_report_name : null
}

output "zesty_account_id" {
  description = "Zesty provider account resource ID."
  value       = zesty_account.result.id
}

output "kompass_values_yaml" {
  description = "The contents of the values.yaml file used to onboard Kompass. Null when Kompass is disabled."
  value       = local.values_content
  sensitive   = true
}

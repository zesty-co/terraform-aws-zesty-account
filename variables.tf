variable "cm" {
  description = "Commitment Manager configuration. Omit to disable CM. Pass cm = {} to enable CM with defaults. cm.enabled is retained only for backward compatibility."
  type = object({
    enabled = optional(bool, true)
  })
  default = null
}

variable "kompass" {
  description = "Kompass configuration. Omit to disable Kompass. Pass kompass = {} to enable Kompass with defaults. kompass.enabled is retained only for backward compatibility."
  type = object({
    enabled = optional(bool, true)
  })
  default = null
}

variable "account_type" {
  description = "AWS account type declared by the customer. Set to management for management/payer and standalone accounts, or linked for linked/member accounts. Standalone is accepted only to return a validation that directs customers to management."
  type        = string
  default     = null

  validation {
    condition     = var.account_type == null ? true : contains(["management", "linked", "standalone"], lower(var.account_type))
    error_message = "account_type must be one of: management, linked, standalone."
  }
}

variable "cur" {
  description = "CUR configuration. Use mode=create to let Terraform create CUR, existing to reference customer-owned CUR, or auto to decide by product/account type."
  type = object({
    mode          = optional(string, "auto")
    type          = optional(string, "cur_v1")
    s3_bucket     = optional(string)
    s3_prefix     = optional(string, "cur")
    report_name   = optional(string, "ZestyCurReport")
    export_name   = optional(string)
    region        = optional(string)
    force_destroy = optional(bool, true)
  })
  default = {}

  validation {
    condition     = contains(["auto", "create", "existing"], lower(var.cur.mode))
    error_message = "cur.mode must be one of: auto, create, existing."
  }

  validation {
    condition     = contains(["cur_v1", "cur_v2"], lower(var.cur.type))
    error_message = "cur.type must be one of: cur_v1, cur_v2."
  }
}

variable "role_name" {
  description = "IAM role name."
  type        = string
  default     = "ZestyIamRole"
}

variable "policy_name" {
  description = "IAM inline policy name."
  type        = string
  default     = "ZestyPolicy"
}

variable "trusted_principal" {
  description = "Trusted AWS principal allowed to assume the Zesty role."
  type        = string
  default     = "arn:aws:iam::672188301118:root"
}

variable "max_session_duration" {
  description = "Maximum session duration of the assumed role, in seconds."
  type        = number
  default     = 43200
}

variable "region" {
  description = "AWS region sent to Zesty. Defaults to the configured AWS provider region."
  type        = string
  default     = ""
}

variable "cur_s3_bucket_prefix" {
  description = "Prefix used when the module creates the CUR bucket."
  type        = string
  default     = "zesty-cur-bucket"
}

variable "cur_s3_bucket" {
  description = "Backward-compatible alias for cur_s3_bucket_prefix from the existing management Kompass module."
  type        = string
  default     = null
}

variable "glue_db_name" {
  description = "Glue database name for management-account Kompass CUR access."
  type        = string
  default     = "zesty_cur"
}

variable "glue_crawler_name" {
  description = "Glue crawler and crawler role/policy name."
  type        = string
  default     = "zesty_cur_glue_crawler"
}

variable "athena_workgroup" {
  description = "Athena workgroup name."
  type        = string
  default     = "ZestyCur"
}

variable "athena_result_directory" {
  description = "Athena query result directory in the CUR S3 bucket."
  type        = string
  default     = "zesty-athena-results"
}

variable "create_values_local_file" {
  description = "Create a local values.yaml file for Kompass."
  type        = bool
  default     = false
}

variable "values_yaml_filename" {
  description = "Path for the generated Kompass values file."
  type        = string
  default     = "values.yaml"
}

variable "iam_propagation_delay" {
  description = "Duration to wait after IAM role policy changes before calling Zesty validation."
  type        = string
  default     = "20s"
}

variable "enable_organization_trust" {
  description = "Add an org-wide trust statement to the Zesty IAM role. Enable only when linked-account Kompass clusters need to assume this management-account role for CUR/Athena access. Leave false for standalone accounts."
  type        = bool
  default     = false
}

variable "trusted_organization_id" {
  description = "AWS Organization ID to use in the org-wide trust condition. When empty and enable_organization_trust is true, the organization ID is auto-discovered via the Organizations API."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to created AWS resources that support tagging."
  type        = map(string)
  default     = {}
}

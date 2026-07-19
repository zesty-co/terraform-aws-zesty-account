variable "enabled" {
  description = "Whether Kompass is requested."
  type        = bool
  default     = true
}

variable "account_type" {
  description = "AWS account type configured for this module."
  type        = string
}

variable "glue_db_name" {
  description = "Glue database name used for management-account Kompass."
  type        = string
  default     = "zesty_cur"
}

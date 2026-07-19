locals {
  management_mode = var.enabled && var.account_type == "management"

  product_specs = var.enabled ? [
    {
      name   = "Kompass"
      active = true
    }
  ] : []

  iam_policy_statements = local.management_mode ? [
    {
      Sid    = "AthenaAccess"
      Effect = "Allow"
      Action = [
        "athena:StartQueryExecution",
        "athena:GetQueryExecution",
        "athena:GetQueryResults"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "ReadAccessToAthenaCurDataViaGlue"
      Effect = "Allow"
      Action = [
        "glue:GetDatabase*",
        "glue:GetTable*",
        "glue:GetPartition*",
        "glue:GetUserDefinedFunction",
        "glue:BatchGetPartition"
      ]
      Resource = [
        "arn:aws:glue:*:*:catalog",
        "arn:aws:glue:*:*:database/${var.glue_db_name}*",
        "arn:aws:glue:*:*:table/${var.glue_db_name}*/*"
      ]
    }
  ] : []
}

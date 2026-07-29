locals {
  region                = var.region != "" ? var.region : data.aws_region.current.region
  declared_account_type = var.account_type == null ? null : lower(var.account_type)
  account_type          = local.declared_account_type
  cm_enabled            = var.cm == null ? false : var.cm.enabled
  kompass_enabled       = var.kompass == null ? false : var.kompass.enabled

  cur_mode          = lower(var.cur.mode)
  cur_type          = lower(var.cur.type)
  cur_bucket_prefix = coalesce(var.cur_s3_bucket, var.cur_s3_bucket_prefix)
  cur_s3_prefix     = var.cur.s3_prefix
  cur_region        = coalesce(var.cur.region, local.region)
  cur_report_name   = coalesce(var.cur.export_name, var.cur.report_name)

  organization_id = var.trusted_organization_id != "" ? var.trusted_organization_id : try(data.aws_organizations_organization.current[0].id, "")

  organization_trust_statement = var.enable_organization_trust ? [
    {
      Sid    = "AllowOrganizationAssume"
      Effect = "Allow"
      Action = [
        "sts:AssumeRole",
        "sts:TagSession",
      ]
      Principal = {
        AWS = "*"
      }
      Condition = {
        StringEquals = {
          "aws:PrincipalOrgID" = local.organization_id
          "sts:ExternalId"     = random_uuid.zesty_external_id.result
        }
      }
    }
  ] : []

  base_readonly_management = local.account_type == "management" && length(local.effective_products) == 0
  requires_cur             = local.base_readonly_management || module.cm.requirements.requires_cur || module.kompass.requirements.requires_cur
  should_create_cur        = local.cur_mode == "create" || (local.cur_mode == "auto" && local.requires_cur)
  uses_existing_cur        = local.cur_mode == "existing"
  has_cur                  = local.should_create_cur || (local.uses_existing_cur && try(length(var.cur.s3_bucket) > 0, false))

  cur_bucket_name = local.should_create_cur ? aws_s3_bucket.zesty_cur_bucket[0].bucket : var.cur.s3_bucket
  cur_bucket_arn  = local.cur_bucket_name != null ? "arn:aws:s3:::${local.cur_bucket_name}" : null
  cur_bucket_resources = compact([
    local.cur_bucket_arn,
    local.cur_bucket_arn != null ? "${local.cur_bucket_arn}/*" : null
  ])

  effective_products = flatten([module.cm.product_specs, module.kompass.product_specs])

  values_content = module.kompass.enabled ? try([
    for p in zesty_account.result.account.products : p.values
    if p.name == "Kompass" && p.active == true
  ][0], null) : null

  shared_policy_statements = [
    {
      Sid    = "EC2Access"
      Effect = "Allow"
      Action = [
        "ec2:List*",
        "ec2:Describe*",
        "elasticloadbalancing:Describe*",
        "autoscaling:Describe*"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "OrganizationsAccess"
      Effect = "Allow"
      Action = [
        "organizations:List*",
        "organizations:Describe*"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "ServiceQuotasAccess"
      Effect = "Allow"
      Action = [
        "servicequotas:ListServiceQuotas",
        "servicequotas:GetServiceQuota",
        "servicequotas:GetRequestedServiceQuotaChange"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "MetricsAccess"
      Effect = "Allow"
      Action = [
        "cloudwatch:List*",
        "cloudwatch:Describe*",
        "cloudwatch:GetMetricStatistics"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "SavingsPlansAccess"
      Effect = "Allow"
      Action = module.kompass.management_mode ? [
        "savingsplans:List*",
        "savingsplans:Describe*",
        "savingsplans:CreateSavingsPlan"
        ] : [
        "savingsplans:List*",
        "savingsplans:Describe*"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "CostExplorerAccess"
      Effect = "Allow"
      Action = [
        "ce:List*",
        "ce:Describe*",
        "ce:Get*"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "EKSAccess"
      Effect = "Allow"
      Action = [
        "eks:List*",
        "eks:Describe*"
      ]
      Resource = ["*"]
    }
  ]

  payer_policy_statements = [
    {
      Sid    = "AllowPricingListPriceLists"
      Effect = "Allow"
      Action = [
        "pricing:ListPriceLists"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "BCMDataExportsAccess"
      Effect = "Allow"
      Action = [
        "bcm-data-exports:ListExports",
        "bcm-data-exports:GetExport"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "CostAndUsageReportAccess"
      Effect = "Allow"
      Action = [
        "cur:DescribeReportDefinitions"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "S3AccessToCurBucket"
      Effect = "Allow"
      Action = module.kompass.management_mode ? [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:GetBucketLocation"
        ] : [
        "s3:Get*",
        "s3:List*"
      ]
      Resource = local.cur_bucket_resources
    }
  ]

  zesty_policy_statements = concat(
    local.shared_policy_statements,
    local.requires_cur ? local.payer_policy_statements : [],
    module.kompass.iam_policy_statements,
    module.cm.iam_policy_statements
  )

  zesty_account_base_payload = {
    id             = data.aws_caller_identity.current.account_id
    region         = local.region
    cloud_provider = "AWS"
    role_arn       = aws_iam_role.zesty_iam_role.arn
    external_id    = random_uuid.zesty_external_id.result
    products       = local.effective_products
  }

  cur_account_payload = local.requires_cur ? {
    cur = {
      s3_bucket       = local.cur_bucket_name
      cur_export_name = local.cur_report_name
      cur_type        = local.cur_type
    }
  } : {}

  athena_account_payload = module.kompass.management_mode ? {
    athena = {
      athena_db         = aws_glue_catalog_database.zesty_cur_db[0].name
      athena_s3_bucket  = aws_athena_workgroup.zesty_athena[0].configuration[0].result_configuration[0].output_location
      athena_project_id = data.aws_caller_identity.current.account_id
      athena_region     = local.region
      athena_table      = aws_glue_catalog_database.zesty_cur_db[0].name
      athena_workgroup  = aws_athena_workgroup.zesty_athena[0].name
      athena_catalog    = "AwsDataCatalog"
    }
  } : {}

  zesty_account_payload = merge(
    local.zesty_account_base_payload,
    local.cur_account_payload,
    local.athena_account_payload
  )
}

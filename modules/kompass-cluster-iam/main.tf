locals {
  iam_enabled                      = var.irsa_enabled || var.pod_identity_enabled
  pod_identity_association_enabled = var.pod_identity_enabled && var.create_pod_identity_association
  management_role_configured       = var.management_role_arn != null

  oidc_host = var.irsa_enabled ? try(split("oidc-provider/", var.oidc_provider_arn)[1], "") : ""

  irsa_values = var.irsa_enabled ? yamlencode({
    "kompass-insights" = {
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.insights_agent[0].arn
        }
      }
      selfMonitoring = {
        serviceAccount = {
          annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.insights_agent[0].arn
          }
        }
      }
    }
  }) : ""

  management_role_values = local.management_role_configured ? yamlencode({
    "kompass-insights" = {
      assumeRole = merge(
        { masterRoleArn = var.management_role_arn },
        var.management_role_external_id != "" ? { masterExternalID = var.management_role_external_id } : {}
      )
    }
  }) : ""

}

# ── insights-agent IAM role ────────────────────────────────────────────────────

data "aws_iam_policy_document" "insights_agent_irsa_trust" {
  count = var.irsa_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values = [
        "system:serviceaccount:${var.namespace}:${var.service_account_name}",
        "system:serviceaccount:${var.namespace}:${var.self_monitoring_service_account_name}",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "insights_agent_pod_identity_trust" {
  count = var.pod_identity_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "insights_agent" {
  count      = local.iam_enabled ? 1 : 0
  depends_on = [terraform_data.validation]

  name        = var.insights_agent_role_name
  description = "Assumed by the Zesty Kompass insights-agent pod to access AWS APIs for cluster metadata, cost analysis, and EKS nodepool discovery."

  assume_role_policy = var.irsa_enabled ? data.aws_iam_policy_document.insights_agent_irsa_trust[0].json : data.aws_iam_policy_document.insights_agent_pod_identity_trust[0].json
}

resource "aws_iam_role_policy" "insights_agent" {
  count = local.iam_enabled ? 1 : 0

  name = "${coalesce(var.insights_agent_role_name, "ZestyInsightsAgent")}-Policy"
  role = aws_iam_role.insights_agent[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "EC2Access"
          Effect = "Allow"
          # ec2:Get* is intentionally excluded — it includes ec2:GetPasswordData
          # which retrieves Windows administrator passwords and must not be granted.
          Action = [
            "ec2:Describe*",
            "ec2:List*",
          ]
          Resource = "*"
        },
        {
          Sid    = "EKSAccess"
          Effect = "Allow"
          Action = [
            "eks:Describe*",
            "eks:List*",
          ]
          Resource = "*"
        },
        {
          Sid    = "AutoScalingAccess"
          Effect = "Allow"
          Action = [
            "autoscaling:Describe*",
          ]
          Resource = "*"
        },
        {
          Sid    = "PricingAccess"
          Effect = "Allow"
          # The Pricing API is only available in us-east-1; the agent targets
          # that region explicitly for these calls regardless of cluster region.
          Action = [
            "pricing:List*",
            "pricing:Get*",
          ]
          Resource = "*"
        },
      ],
      local.management_role_configured ? [
        {
          Sid    = "AssumeManagementRole"
          Effect = "Allow"
          Action = [
            "sts:AssumeRole",
            "sts:TagSession",
          ]
          Resource = var.management_role_arn
        }
      ] : []
    )
  })
}

# Binds the IAM role to a specific cluster + namespace + ServiceAccount.
# Prerequisite: eks-pod-identity-agent addon must be installed on the cluster.
resource "aws_eks_pod_identity_association" "insights_agent" {
  count = local.pod_identity_association_enabled ? 1 : 0

  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.service_account_name
  role_arn        = aws_iam_role.insights_agent[0].arn
}

resource "aws_eks_pod_identity_association" "insights_agent_self_monitoring" {
  count = local.pod_identity_association_enabled ? 1 : 0

  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.self_monitoring_service_account_name
  role_arn        = aws_iam_role.insights_agent[0].arn
}

resource "terraform_data" "validation" {
  lifecycle {
    precondition {
      condition     = !(var.irsa_enabled && var.pod_identity_enabled)
      error_message = "irsa_enabled and pod_identity_enabled are mutually exclusive."
    }
    precondition {
      condition     = !local.iam_enabled || try(length(trimspace(var.insights_agent_role_name)) > 0, false)
      error_message = "insights_agent_role_name must be non-empty when creating a pod IAM role."
    }
    precondition {
      condition     = !var.irsa_enabled || can(regex("^arn:[^:]+:iam::[0-9]{12}:oidc-provider/.+", var.oidc_provider_arn))
      error_message = "oidc_provider_arn must be an IAM OIDC provider ARN when irsa_enabled is true."
    }
    precondition {
      condition     = !local.pod_identity_association_enabled || try(length(trimspace(var.cluster_name)) > 0, false)
      error_message = "cluster_name is required when creating Pod Identity associations."
    }
  }
}

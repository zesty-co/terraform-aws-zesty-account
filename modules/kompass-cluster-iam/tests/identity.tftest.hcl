mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/test-insights" }
  }
}

run "pod_identity_without_helm" {
  command = apply
  variables {
    pod_identity_enabled     = true
    cluster_name             = "test-cluster"
    insights_agent_role_name = "test-insights"
  }
  assert {
    condition     = aws_eks_pod_identity_association.insights_agent[0].cluster_name == "test-cluster" && aws_eks_pod_identity_association.insights_agent_self_monitoring[0].cluster_name == "test-cluster"
    error_message = "Both pod identities must bind to the caller's cluster."
  }
  assert {
    condition     = !can(yamldecode(output.helm_values_yaml)["kompass-insights"].serviceAccount.annotations)
    error_message = "Pod Identity must not add IRSA annotations."
  }
}

run "irsa_and_management_overlays" {
  command = apply
  variables {
    irsa_enabled                = true
    oidc_provider_arn           = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
    insights_agent_role_name    = "test-insights"
    management_role_arn         = "arn:aws:iam::111122223333:role/ZestyIamRole"
    management_role_external_id = "test-external-id"
  }
  assert {
    condition     = yamldecode(output.helm_values_yaml)["kompass-insights"].serviceAccount.annotations["eks.amazonaws.com/role-arn"] == output.insights_agent_role_arn && yamldecode(output.helm_values_yaml)["kompass-insights"].selfMonitoring.serviceAccount.annotations["eks.amazonaws.com/role-arn"] == output.insights_agent_role_arn
    error_message = "Both ServiceAccounts must receive the same IRSA role."
  }
  assert {
    condition     = yamldecode(output.helm_values_yaml)["kompass-insights"].assumeRole.masterExternalID == "test-external-id" && length(aws_eks_pod_identity_association.insights_agent) == 0
    error_message = "Management credentials must survive composition without creating Pod Identity associations in IRSA mode."
  }
}

run "external_identity" {
  command = apply
  assert {
    condition     = output.insights_agent_role_arn == null && length(aws_iam_role.insights_agent) == 0 && length(output.helm_values) == 0
    error_message = "External identity must not create IAM resources or override values."
  }
}

run "reject_conflicting_identity_modes" {
  command = plan
  variables {
    irsa_enabled             = true
    pod_identity_enabled     = true
    cluster_name             = "test-cluster"
    insights_agent_role_name = "test-insights"
    oidc_provider_arn        = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
  }
  expect_failures = [terraform_data.validation]
}
run "reject_missing_cluster_for_associations" {
  command = plan
  variables {
    pod_identity_enabled     = true
    insights_agent_role_name = "test-insights"
  }
  expect_failures = [terraform_data.validation]
}

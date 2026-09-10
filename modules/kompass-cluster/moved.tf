moved {
  from = data.aws_iam_policy_document.insights_agent_irsa_trust
  to   = module.iam.data.aws_iam_policy_document.insights_agent_irsa_trust
}

moved {
  from = data.aws_iam_policy_document.insights_agent_pod_identity_trust
  to   = module.iam.data.aws_iam_policy_document.insights_agent_pod_identity_trust
}

moved {
  from = aws_iam_role.insights_agent
  to   = module.iam.aws_iam_role.insights_agent
}

moved {
  from = aws_iam_role_policy.insights_agent
  to   = module.iam.aws_iam_role_policy.insights_agent
}

moved {
  from = aws_eks_pod_identity_association.insights_agent
  to   = module.iam.aws_eks_pod_identity_association.insights_agent
}

moved {
  from = aws_eks_pod_identity_association.insights_agent_self_monitoring
  to   = module.iam.aws_eks_pod_identity_association.insights_agent_self_monitoring
}

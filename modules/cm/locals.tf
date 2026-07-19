locals {
  product_specs = var.enabled ? [
    {
      name   = "CM"
      active = true
    }
  ] : []

  iam_policy_statements = var.enabled ? [
    {
      Sid    = "EC2AccessCM"
      Effect = "Allow"
      Action = [
        "ec2:CreateReservedInstancesListing",
        "ec2:PurchaseReservedInstancesOffering",
        "ec2:PurchaseHostReservation",
        "ec2:GetReservedInstancesExchangeQuote",
        "ec2:AcceptReservedInstancesExchangeQuote",
        "ec2:CancelReservedInstancesListing",
        "ec2:ModifyReservedInstances"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "ServiceQuotasAccessCM"
      Effect = "Allow"
      Action = [
        "servicequotas:RequestServiceQuotaIncrease"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "SavingsPlansAccessCM"
      Effect = "Allow"
      Action = [
        "savingsplans:*"
      ]
      Resource = ["*"]
    }
  ] : []
}

# Zesty AWS Account Terraform Module

Onboard AWS accounts to Zesty products with Terraform.

This module creates the account-level resources Zesty needs:

- IAM role and policy that Zesty can assume
- Zesty account registration through the `zesty` Terraform provider
- CUR resources when the module creates Cost and Usage Reports
- Athena and Glue resources when Kompass is enabled on a management account
- Kompass Helm values when Kompass is enabled

Use one module block per AWS account. If you want to onboard products in more
than one AWS account, add one module block for each account with the right AWS
provider alias.

## Requirements

- Terraform `>= 1.5`
- AWS provider `~> 6.0`
- Zesty provider `~> 0.3.0`
- AWS credentials for the account being onboarded
- A Zesty API token configured for the `zesty` provider

Set the Zesty API token in the environment before running Terraform:

```bash
export ZESTY_API_TOKEN="<your-zesty-api-token>"
```

Keep the token out of Terraform configuration and version control.

## Product Blocks

Product blocks are presence-based:

- omit a product block to disable that product
- pass an empty block, such as `cm = {}` or `kompass = {}`, to enable it with defaults
- `enabled = false` is still accepted for backward compatibility

Example:

```hcl
module "zesty_account" {
  source  = "zesty-co/zesty-account/aws"
  version = "~> 0.1"

  account_type = "management"

  cm      = {}
  kompass = {}
}
```

No product blocks means base read-only onboarding.

## Account Types

Set `account_type` to match the AWS account you are onboarding:

| Account type | Use for | CUR | Athena/Glue |
| --- | --- | --- | --- |
| `management` | AWS Organizations management/payer account | Created or referenced when needed | Created when Kompass is enabled |
| `linked` | AWS Organizations linked/member account | Not created | Not created |

Standalone AWS accounts are not supported yet.

## Examples

### Base Read-Only Management Account

Creates the Zesty IAM role, creates CUR, and registers the account without
enabling CM or Kompass automation.

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "zesty" {}

module "zesty_account" {
  source  = "zesty-co/zesty-account/aws"
  version = "~> 0.1"

  account_type = "management"
}
```

### CM On A Management Account

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "zesty" {}

module "zesty_account" {
  source  = "zesty-co/zesty-account/aws"
  version = "~> 0.1"

  account_type = "management"

  cm = {}
}
```

### CM With An Existing CUR

Use this when the management account already has a CUR that Zesty should read
instead of creating a new one.

```hcl
module "zesty_account" {
  source  = "zesty-co/zesty-account/aws"
  version = "~> 0.1"

  account_type = "management"

  cm = {}

  cur = {
    mode        = "existing"
    type        = "cur_v2"
    s3_bucket   = "my-existing-cur-bucket"
    export_name = "my-existing-cur-export"
  }
}
```

### Kompass On A Linked Account

Creates the Zesty IAM role and returns `kompass_values_yaml` for installing
Kompass into EKS. Linked accounts do not create CUR, Athena, or Glue.

```hcl
module "zesty_account" {
  source  = "zesty-co/zesty-account/aws"
  version = "~> 0.1"

  account_type = "linked"

  kompass = {}
}

output "kompass_values_yaml" {
  value     = module.zesty_account.kompass_values_yaml
  sensitive = true
}
```

### CM In Management + Kompass In Linked

Many customers use one management account for billing and one or more linked
accounts for EKS clusters. In that case, use one module block for each AWS
account.

```hcl
provider "aws" {
  alias  = "management"
  region = "us-east-1"
}

provider "aws" {
  alias  = "linked"
  region = "us-east-1"
}

provider "zesty" {}

module "management_account" {
  source  = "zesty-co/zesty-account/aws"
  version = "~> 0.1"

  providers = {
    aws = aws.management
  }

  account_type = "management"

  cm = {}
}

module "linked_account" {
  source  = "zesty-co/zesty-account/aws"
  version = "~> 0.1"

  providers = {
    aws = aws.linked
  }

  account_type = "linked"

  kompass = {}
}
```

### Kompass And CM On A Management Account

```hcl
module "zesty_account" {
  source  = "zesty-co/zesty-account/aws"
  version = "~> 0.1"

  account_type = "management"

  cm      = {}
  kompass = {}
}
```

## Kompass Cluster Installation

Kompass account onboarding and Kompass cluster installation are separate steps.
The account module outputs `kompass_values_yaml`; the cluster module uses those
values to install the Kompass Helm chart into an EKS cluster.

The EKS cluster is selected by the caller's Helm provider configuration.

```hcl
variable "cluster_name" {
  type = string
}

provider "aws" {
  region = "us-west-2"
}

data "aws_eks_cluster" "target" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "target" {
  name = data.aws_eks_cluster.target.name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.target.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.target.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.target.token
  }
}

module "zesty_account" {
  source  = "zesty-co/zesty-account/aws"
  version = "~> 0.1"

  account_type = "linked"

  kompass = {}
}

module "kompass_cluster" {
  source  = "zesty-co/zesty-account/aws//modules/kompass-cluster"
  version = "~> 0.1"

  kompass_values_yaml = module.zesty_account.kompass_values_yaml

  pod_identity_enabled     = true
  cluster_name             = var.cluster_name
  insights_agent_role_name = "ZestyInsightsAgent-${var.cluster_name}"
}
```

To install Kompass into multiple EKS clusters, configure one Helm provider alias
per cluster and call `modules/kompass-cluster` once per cluster. See
`examples/kompass-multi-cluster`.

## Existing CUR

For management accounts, CUR can be created by this module or supplied by the
customer.

```hcl
cur = {
  mode        = "existing"
  type        = "cur_v2"
  s3_bucket   = "my-existing-cur-bucket"
  export_name = "my-existing-cur-export"
}
```

When `cur.mode = "create"`, the module currently creates CUR v1 with
`aws_cur_report_definition`. To use CUR v2, set `cur.mode = "existing"`.

## Inputs

| Name | Description | Default |
| --- | --- | --- |
| `account_type` | AWS account type: `management` or `linked` | Required |
| `cm` | Enable Commitment Manager when present | `null` |
| `kompass` | Enable Kompass account onboarding when present | `null` |
| `cur` | CUR mode and details | `{ mode = "auto", type = "cur_v1" }` |
| `role_name` | Zesty IAM role name | `ZestyIamRole` |
| `policy_name` | Zesty IAM inline policy name | `ZestyPolicy` |
| `trusted_principal` | AWS principal trusted to assume the Zesty role | Zesty default |
| `region` | AWS region sent to Zesty | AWS provider region |
| `create_values_local_file` | Write Kompass values to a local file | `false` |
| `iam_propagation_delay` | Wait after IAM changes before Zesty validation | `20s` |
| `tags` | Tags applied to created AWS resources | `{}` |

See `variables.tf` for the full input list.

## Outputs

| Name | Description |
| --- | --- |
| `account_id` | AWS account ID onboarded to Zesty |
| `account_type` | Account type used by the module |
| `role_arn` | IAM role ARN assumed by Zesty |
| `external_id` | External ID configured in the IAM trust policy |
| `cur_bucket` | CUR S3 bucket name when CUR is configured |
| `cur_export_name` | CUR report/export name sent to Zesty |
| `zesty_account_id` | Zesty provider account resource ID |
| `kompass_values_yaml` | Helm values YAML for Kompass cluster installation |

`external_id` and `kompass_values_yaml` are sensitive outputs. Terraform stores
them in state, so protect access to the state backend.

## Current Limitations

- CM automation is supported on management/payer accounts only.
- Standalone AWS accounts are not supported yet.
- Creating CUR through this module currently creates CUR v1. Use
  `cur.mode = "existing"` for CUR v2.
- UI/CloudFormation to Terraform migration requires an adoption plan before the
  same AWS account is managed by Terraform.
- Kompass cluster installation is separate from account onboarding because one
  AWS account can have multiple EKS clusters.

## Destroying The Module

`terraform destroy` removes AWS resources created by this module and removes
the Terraform account registration from Zesty. It does not delete an existing
CUR supplied with `cur.mode = "existing"`. Coordinate production offboarding
with Zesty Support before destroying the module so product-side cleanup can be
confirmed.

## Support

For product documentation, visit [Zesty documentation](https://docs.zesty.co/).
Contact Zesty Support for onboarding or migration assistance.

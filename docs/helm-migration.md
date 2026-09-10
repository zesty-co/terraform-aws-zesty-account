# Upgrading Helm/IAM ownership

## Existing wrapper

Keep the caller's `module "kompass_cluster"` address and inputs. The wrapper's
`moved` declarations transfer its IAM role, inline policy, and both Pod Identity
associations to the internal IAM module. `helm_release.kompass` retains its
address. Review `terraform plan`: no IAM role/association replacement should
occur. New validation state is expected. Back up remote state normally first.

## Switch to customer-owned Helm

Do not simply remove the wrapper: Terraform would destroy its resources. First
configure the AWS-only `kompass-cluster-iam` module with identical inputs. Move
the existing `module.kompass_cluster.module.iam` state to that new module address
(using reviewed `moved` declarations or `terraform state mv`). If moving directly
from 0.1.1, move the individual IAM resource addresses listed in the wrapper's
`moved.tf`; they have not yet acquired the nested `module.iam` address.

For a caller-owned `helm_release`, move the release state too. For Helm CLI/GitOps,
remove only the Helm release from Terraform state with `terraform state rm` after
reviewing the address and configuring the new owner. This relinquishes Terraform
ownership without uninstalling the release. Preserve name, namespace, chart
version, values, and credentials. Run a no-destroy plan before the new owner
updates anything. Do not let both tools manage the same release concurrently.

## Existing generated local values file

The root module now uses `local_sensitive_file` with mode `0600`. Terraform 1.5
and local provider 2.5 do not offer a portable automatic cross-resource-type move.
If `create_values_local_file = true` was used, back up the values file privately
and remove ONLY its old `local_file.kompass_values[0]` address from state before
applying this upgrade. For an account module called `zesty_account`:

```sh
terraform state rm 'module.zesty_account.local_file.kompass_values[0]'
chmod 600 /path/to/your/existing/values.yaml
terraform plan
terraform apply
```

The explicit `chmod` is required for an existing file: the local provider may
preserve its previous permissions when overwriting it. New files are created with
mode `0600`. Use your configured values-file path in the command above. The state command
does not remove the file on disk or affect account/IAM resources. Use the exact
address from `terraform state list` (older uncounted addresses may differ). No
step is needed if local-file creation was disabled. Generated values remain in
Terraform state; sensitive marking is redaction, not encryption.

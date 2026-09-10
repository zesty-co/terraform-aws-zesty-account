module "iam" {
  source = "../kompass-cluster-iam"

  namespace                            = var.namespace
  irsa_enabled                         = var.irsa_enabled
  pod_identity_enabled                 = var.pod_identity_enabled
  insights_agent_role_name             = var.insights_agent_role_name
  service_account_name                 = var.service_account_name
  self_monitoring_service_account_name = var.self_monitoring_service_account_name
  oidc_provider_arn                    = var.oidc_provider_arn
  cluster_name                         = var.cluster_name
  create_pod_identity_association      = var.create_pod_identity_association
  management_role_arn                  = var.management_role_arn
  management_role_external_id          = var.management_role_external_id
}

locals {
  storage_class_values_yaml = var.storage_class_name == null ? null : yamlencode({
    global = {
      storageClassName = var.storage_class_name
    }
    "kompass-insights" = {
      persistence = {
        spec = {
          storageClassName = var.storage_class_name
        }
      }
    }
    victoriaMetrics = {
      server = {
        persistentVolume = {
          storageClassName = var.storage_class_name
        }
      }
    }
    victoriaMetricsCluster = {
      vmselect = {
        persistentVolume = {
          storageClassName = var.storage_class_name
        }
      }
      vmstorage = {
        persistentVolume = {
          storageClassName = var.storage_class_name
        }
      }
    }
    grafana = {
      persistence = {
        storageClassName = var.storage_class_name
      }
    }
    "kompass-storage" = {
      storageClassName = var.storage_class_name
    }
  })

  cluster_values = [
    for value in [
      local.storage_class_values_yaml,
    ] : value
    if value != null
  ]
}

resource "helm_release" "kompass" {
  name             = var.release_name
  repository       = var.repository
  chart            = var.chart
  version          = var.chart_version
  namespace        = var.namespace
  cleanup_on_fail  = var.cleanup_on_fail
  create_namespace = var.create_namespace
  wait             = var.wait
  timeout          = var.timeout

  values = concat([var.kompass_values_yaml], module.iam.helm_values, local.cluster_values, var.extra_values)

  lifecycle {
    precondition {
      condition     = !(var.irsa_enabled && var.pod_identity_enabled)
      error_message = "irsa_enabled and pod_identity_enabled are mutually exclusive. Set only one to true."
    }
  }
}

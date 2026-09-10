# Storage configuration

Storage is cluster-scoped. The account backend now emits account credentials and
metadata without choosing a StorageClass. On a cluster with a suitable default
and provisioner, omit storage overrides. `storage_class_name = null` in the
Terraform wrapper preserves generated values; it does not erase names emitted
by an older backend.

The wrapper's optional `storage_class_name` still sets the component paths for
compatibility. For customer-owned Helm, pass a separate `cluster-values.yaml`:

```yaml
# Anchors apply within THIS overlay file, not retroactively to chart defaults.
global:
  storageClassName: &storageClass gp3
kompass-insights:
  persistence:
    spec:
      storageClassName: *storageClass
victoriaMetrics:
  server:
    persistentVolume:
      storageClassName: *storageClass
victoriaMetricsCluster:
  vmstorage:
    persistentVolume:
      storageClassName: *storageClass
  vmselect:
    persistentVolume:
      storageClassName: *storageClass
grafana:
  persistence:
    storageClassName: *storageClass
```

Replace `gp3` with an existing appropriate class. To clear old backend overrides
and use the cluster default, use `null` as the anchor value instead. Do not use an
empty string as a generic default: Kubernetes distinguishes classless PVCs from
unspecified storage. Existing bound PVCs cannot generally change StorageClass in
place. Retain their existing class during upgrades; migrate data separately if
changing storage is necessary.

Setting only `global.storageClassName` in a later file does not propagate to the
bundled third-party charts. Each component setting is authoritative. The fixed
chart validator checks classes actually used by enabled components, including
Grafana, and checks for a cluster default when needed. It no longer invents
`ebs-sc` or requires a particular CSI controller Deployment name.

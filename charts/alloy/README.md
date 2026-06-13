# alloy

Grafana Alloy collector wired to Grafana Cloud, intended as the unified
replacement for the `prometheus` (metrics remote_write) and `promtail` (logs)
charts in this repo.

A single Alloy `Deployment`:

- scrapes Prometheus annotation-based service endpoints, applies the cost-control
  metric allowlist, and `remote_write`s to Grafana Cloud;
- tails pod logs through the Kubernetes API and `loki.write`s them to Grafana
  Cloud Loki.

One instance avoids duplicate metric scraping (vs a DaemonSet) and needs no host
mounts. The bundled `sealed-secret` subchart materialises the Grafana Cloud
credentials Secret, so **no credential is ever stored in plaintext**.

## Credentials & endpoints

| Source | Keys | Provided by |
|--------|------|-------------|
| Sealed Secret (`alloy-grafana-cloud`) via `alloy.alloy.envFrom` | `PROM_USER`, `PROM_PASS`, `LOKI_USER`, `LOKI_PASS` | consumer injects `AgB…` blobs into `sealed-secret.encryptedData.*` |
| Plain env via `alloy.alloy.extraEnv` | `PROM_URL`, `LOKI_URL`, `CLUSTER` | consumer (e.g. `do-boostraping`) |

The River config references everything through `sys.env(...)`, so this chart
stays generic and ships no environment-specific values.

## Dependencies

| Chart | Version | Repo |
|-------|---------|------|
| `alloy` (upstream) | `1.10.0` | grafana.github.io/helm-charts |
| `sealed-secret` | `1.0.*` | moreirodamian.github.io/helm-charts |

## RBAC

The upstream chart's ClusterRole covers discovery; `templates/rbac-logs.yaml`
adds only `pods/log` (least privilege) bound to the fixed `alloy` ServiceAccount,
required by `loki.source.kubernetes`.

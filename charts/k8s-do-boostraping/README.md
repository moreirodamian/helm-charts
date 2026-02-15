# k8s-do-boostraping

ArgoCD-based bootstrap chart for DigitalOcean Kubernetes (DOKS) clusters. Deploys infrastructure components as ArgoCD Application resources. Features smart conditional logic where some components require both an enabled flag and valid configuration to deploy.

**Chart version:** 0.0.25

## Prerequisites

- DigitalOcean Kubernetes cluster
- ArgoCD installed and running in the `argocd` namespace
- Helm 3+

## Installation

```bash
helm install do-bootstrap ./charts/k8s-do-boostraping \
  --set apps.suffix=production \
  --set apps.destination.name=my-do-cluster
```

## Components

| Component | Condition | Description |
|---|---|---|
| `argo-rollouts` | `apps.rollout.enabled` | Progressive delivery controller |
| `cert-manager` | `apps.certManager.enabled` | TLS certificate management (with optional DNS-01 issuers) |
| `ingress-nginx` | `apps.ingress.enabled` | NGINX ingress controller (with DO load balancer config) |
| `metrics-server` | `apps.metricsServer.version` is set | Kubernetes metrics server |
| `prometheus` | `apps.prometheus.enabled` AND `prometheus.remoteWrite.url` is set | Prometheus stack with remote write |
| `promtail` | `apps.promtail.enabled` AND `promtail.url` is set | Log aggregation agent |
| `sealed-secrets` | `apps.sealedSecrets.enabled` | Bitnami Sealed Secrets controller |

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `apps.suffix` | Suffix appended to ArgoCD Application names | `dev` |
| `apps.destination.name` | ArgoCD destination cluster name | `test-cluster-name` |
| `apps.project` | ArgoCD project name (overrides default `infra-<suffix>`) | `""` |
| `apps.ingress.enabled` | Deploy ingress-nginx | `true` |
| `apps.certManager.enabled` | Deploy cert-manager | `true` |
| `apps.certManager.digitalocean.dns` | Enable DigitalOcean DNS-01 solver | `false` |
| `apps.certManager.digitalocean.token` | Encrypted DO API token for DNS-01 (enables issuer if set) | `~` |
| `apps.certManager.cloudflare.dns` | Enable Cloudflare DNS-01 solver | `false` |
| `apps.certManager.cloudflare.token` | Encrypted Cloudflare API token for DNS-01 (enables issuer if set) | `~` |
| `apps.prometheus.enabled` | Deploy Prometheus (also requires `prometheus.remoteWrite.url`) | `true` |
| `apps.promtail.enabled` | Deploy Promtail (also requires `promtail.url`) | `true` |
| `apps.rollout.enabled` | Deploy Argo Rollouts | `true` |
| `apps.sealedSecrets.enabled` | Deploy Sealed Secrets controller | `false` |
| `apps.metricsServer.version` | Metrics server chart version (set to enable) | `3.13.0` |
| `ingress.loadbalancerName` | DigitalOcean load balancer hostname | `do-loadbalacer.com` |
| `ingress.doProxyProtocol.enabled` | Enable DO proxy protocol on the load balancer | `false` |
| `prometheus.remoteWrite.url` | Prometheus remote write endpoint URL | `~` |
| `prometheus.remoteWrite.secret.name` | Secret name for remote write auth | `prom-secret` |
| `prometheus.remoteWrite.secret.username` | Encrypted username for remote write | `~` |
| `prometheus.remoteWrite.secret.password` | Encrypted password for remote write | `~` |
| `prometheus.clusterName` | Cluster label for Prometheus external labels | `~` |
| `promtail.url` | Loki push endpoint URL for Promtail | `~` |

### Example

```yaml
apps:
  suffix: prod
  destination:
    name: my-do-cluster
  ingress:
    enabled: true
  certManager:
    enabled: true
    cloudflare:
      dns: true
      token: AgBY7...encrypted...
  prometheus:
    enabled: true
  promtail:
    enabled: true
  rollout:
    enabled: true
  sealedSecrets:
    enabled: true
  metricsServer:
    version: 3.13.0

ingress:
  loadbalancerName: my-lb.example.com

prometheus:
  remoteWrite:
    url: https://prometheus-remote.example.com/api/v1/write
    secret:
      name: prom-secret
      username: AgBY7...encrypted...
      password: AgBY7...encrypted...
  clusterName: prod-do

promtail:
  url: https://loki.example.com/loki/api/v1/push
```

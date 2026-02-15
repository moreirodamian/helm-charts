# prometheus

Prometheus monitoring stack wrapping [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) 82.0.0. Configured for remote write to Grafana Cloud with filtered metric forwarding. Includes a sealed-secret for Grafana Cloud credentials and a StatsD exporter subchart.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.x
- Sealed Secrets controller
- Grafana Cloud account (for remote write)

## Installation

```bash
helm dependency update
helm install prometheus ./prometheus -n monitoring --create-namespace -f values.yaml
```

## Configuration

### Core

| Parameter | Description | Default |
|---|---|---|
| `kube-prometheus-stack.alertmanager.enabled` | Enable Alertmanager | `false` |
| `kube-prometheus-stack.grafana.enabled` | Enable Grafana | `false` |

### Remote Write (Grafana Cloud)

| Parameter | Description | Default |
|---|---|---|
| `kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite[0].url` | Grafana Cloud Prometheus push URL | `https://prometheus-prod-10-prod-us-central-0.grafana.net/api/prom/push` |
| `kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite[0].basicAuth.username.name` | Secret name for username | `grafana-axter` |
| `kube-prometheus-stack.prometheus.prometheusSpec.remoteWrite[0].basicAuth.password.name` | Secret name for password | `grafana-axter` |
| `kube-prometheus-stack.prometheus.prometheusSpec.externalLabels` | External labels added to all metrics | `{cluster: "testdmv4"}` |
| `kube-prometheus-stack.prometheus.prometheusSpec.replicaExternalLabelName` | Replica external label name | `__replica__` |

### Scrape Configs

| Parameter | Description | Default |
|---|---|---|
| `kube-prometheus-stack.prometheus.prometheusSpec.additionalScrapeConfigs` | Additional scrape configurations | Kubernetes service endpoints + ingress-nginx pods |

The default scrape configs include:
- **kubernetes-service-endpoints**: Discovers services annotated with `prometheus.io/scrape: "true"`, excluding `kube-system` and `prom` namespaces.
- **ingress-nginx-pods**: Scrapes ingress-nginx metrics on port 10254 from the `ingress-nginx` namespace.

### Sealed Secret (Grafana Cloud Credentials)

| Parameter | Description | Default |
|---|---|---|
| `sealed-secret.name` | Secret name | `grafana-axter` |
| `sealed-secret.namespace` | Secret namespace | `monitoring` |
| `sealed-secret.type` | Secret type | `Opaque` |
| `sealed-secret.encryptedData.username` | Sealed Grafana Cloud username | _(required)_ |
| `sealed-secret.encryptedData.password` | Sealed Grafana Cloud API key | _(required)_ |

## Dependencies

| Chart | Version | Repository |
|---|---|---|
| kube-prometheus-stack | 82.0.0 | https://prometheus-community.github.io/helm-charts |
| sealed-secret | 0.1.* | https://moreirodamian.github.io/helm-charts/ |
| prometheus-statsd-exporter | 1.0.* | https://moreirodamian.github.io/helm-charts/ |

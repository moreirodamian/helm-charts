# promtail

Wrapper chart for [Promtail](https://grafana.com/docs/loki/latest/clients/promtail/) 6.17.1 from Grafana. Promtail is an agent that ships local log contents to a Loki instance.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.x
- A Loki-compatible endpoint (e.g., Grafana Cloud Loki)

## Installation

```bash
helm dependency update
helm install promtail ./promtail -n monitoring --create-namespace -f values.yaml
```

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `promtail.config.clients[0].url` | Loki push API URL | `logs-prod-us-central1.grafana.net/loki/api/v1/push` |

All upstream [Promtail chart values](https://github.com/grafana/helm-charts/tree/main/charts/promtail) are supported under the `promtail` key.

## Dependencies

| Chart | Version | Repository |
|---|---|---|
| promtail | 6.17.1 | https://grafana.github.io/helm-charts |

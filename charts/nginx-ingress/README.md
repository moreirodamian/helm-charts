# nginx-ingress

Wrapper chart for [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) 4.14.3 with Prometheus metrics pre-configured.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.x

## Installation

```bash
helm dependency update
helm install ingress-nginx ./nginx-ingress -n ingress-nginx --create-namespace -f values.yaml
```

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `ingress-nginx.controller.metrics.enabled` | Enable Prometheus metrics endpoint | `true` |
| `ingress-nginx.controller.metrics.service.annotations` | Prometheus scrape annotations | `prometheus.io/scrape: "true"`, `prometheus.io/port: "10254"` |
| `ingress-nginx.controller.metrics.service.servicePort` | Metrics service port | `10254` |
| `ingress-nginx.controller.metrics.service.type` | Metrics service type | `ClusterIP` |
| `ingress-nginx.controller.metrics.serviceMonitor.enabled` | Enable ServiceMonitor for Prometheus Operator | `false` |
| `ingress-nginx.controller.metrics.serviceMonitor.scrapeInterval` | ServiceMonitor scrape interval | `30s` |
| `ingress-nginx.controller.metrics.prometheusRule.enabled` | Enable PrometheusRule alerts | `false` |
| `ingress-nginx.controller.extraArgs.metrics-per-host` | Enable per-host metrics | `false` |

All upstream [ingress-nginx values](https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx) are supported under the `ingress-nginx` key.

## Dependencies

| Chart | Version | Repository |
|---|---|---|
| ingress-nginx | 4.14.3 | https://kubernetes.github.io/ingress-nginx |

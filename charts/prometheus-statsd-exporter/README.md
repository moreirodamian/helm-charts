# prometheus-statsd-exporter

Wrapper chart for [prometheus-statsd-exporter](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-statsd-exporter). Translates StatsD metrics into Prometheus format. Pre-configured with a ClusterIP service on port 9102 and Prometheus scrape annotations.

**Chart version:** 1.0.0

## Prerequisites

- Kubernetes 1.16+
- Helm 3+
- Prometheus (or a compatible scraper) running in the cluster

## Installation

```bash
helm repo add moreirodamian https://moreirodamian.github.io/helm-charts/
helm repo update
helm install statsd-exporter moreirodamian/prometheus-statsd-exporter
```

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `prometheus-statsd-exporter.service.type` | Kubernetes service type | `ClusterIP` |
| `prometheus-statsd-exporter.service.port` | Port for the Prometheus metrics endpoint | `9102` |
| `prometheus-statsd-exporter.service.path` | Metrics path | `/metrics` |
| `prometheus-statsd-exporter.service.annotations` | Service annotations for Prometheus discovery | `prometheus.io/scrape: "true"`, `prometheus.io/port: "9102"` |

All configuration values from the upstream [prometheus-statsd-exporter chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-statsd-exporter) can be set under the `prometheus-statsd-exporter` key.

## Dependencies

| Chart | Version | Repository |
|---|---|---|
| `prometheus-statsd-exporter` | 1.0.0 | https://prometheus-community.github.io/helm-charts |

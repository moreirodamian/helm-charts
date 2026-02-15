# sealed-secret

Helm chart for creating individual Bitnami SealedSecret resources. Designed to be used as a dependency by other charts (e.g., the `laravel` chart) to manage encrypted Kubernetes secrets.

**Chart version:** 0.1.5

## Prerequisites

- Kubernetes cluster with the [sealed-secrets controller](https://github.com/bitnami-labs/sealed-secrets) installed
- Helm 3+
- Secrets encrypted with `kubeseal`

## Installation

```bash
helm install my-secret oci://moreirodamian.github.io/helm-charts/sealed-secret \
  --set name=my-secret \
  --set namespace=default \
  --set encryptedData.MY_KEY=<encrypted-value>
```

When used as a dependency in another chart, add to `Chart.yaml`:

```yaml
dependencies:
  - name: sealed-secret
    version: 0.1.*
    repository: https://moreirodamian.github.io/helm-charts/
    condition: sealed-secret.create
```

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `name` | Name of the SealedSecret resource | `sealed-secret` |
| `namespace` | Target namespace for the secret | `default` |
| `global.namespace` | Global namespace override (takes priority over `namespace`) | `""` |
| `labels` | Additional labels for the SealedSecret | `{}` |
| `annotations` | Annotations for the SealedSecret | `sealedsecrets.bitnami.com/cluster-wide: "true"` |
| `encryptedData` | Map of key/value pairs with kubeseal-encrypted values | `{}` |
| `type` | Kubernetes Secret type (e.g., `Opaque`, `kubernetes.io/tls`) | `""` |

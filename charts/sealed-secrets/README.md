# sealed-secrets

Wrapper chart for the [Bitnami Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) controller. Installs the controller that watches for SealedSecret resources and decrypts them into standard Kubernetes Secrets.

**Chart version:** 2.18.1

## Prerequisites

- Kubernetes 1.16+
- Helm 3+

## Installation

```bash
helm repo add moreirodamian https://moreirodamian.github.io/helm-charts/
helm repo update
helm install sealed-secrets moreirodamian/sealed-secrets
```

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `sealed-secrets.fullnameOverride` | Override the controller deployment name | `sealed-secrets-controller` |

All configuration values from the upstream [sealed-secrets chart](https://github.com/bitnami-labs/sealed-secrets/tree/main/helm/sealed-secrets) can be set under the `sealed-secrets` key. For example:

```yaml
sealed-secrets:
  fullnameOverride: sealed-secrets-controller
  resources:
    limits:
      memory: 128Mi
```

## Dependencies

| Chart | Version | Repository |
|---|---|---|
| `sealed-secrets` | 2.18.1 | https://bitnami-labs.github.io/sealed-secrets |

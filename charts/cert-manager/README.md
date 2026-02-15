# cert-manager

Wrapper chart that installs [cert-manager](https://cert-manager.io/) v1.19.3 from Jetstack with custom ClusterIssuer configuration via the `cert-manager-issuer` subchart. Supports HTTP-01 and DNS-01 (DigitalOcean, Cloudflare) ACME challenges.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.x
- Sealed Secrets controller (for storing DNS provider API tokens)

## Installation

```bash
helm dependency update
helm install cert-manager ./cert-manager -n cert-manager --create-namespace -f values.yaml
```

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `cert-manager.installCRDs` | Install cert-manager CRDs | `true` |
| `cert-manager-issuer.email` | Email for Let's Encrypt registration | _(required)_ |
| `cert-manager-issuer.digitalocean.dns` | Enable DigitalOcean DNS-01 ClusterIssuer | `true` |
| `cert-manager-issuer.cloudflare.dns` | Enable Cloudflare DNS-01 ClusterIssuer | `true` |
| `cert-manager-issuer.sealed-secret.name` | SealedSecret name for DO API token | `digitalocean-dns` |
| `cert-manager-issuer.sealed-secret.namespace` | SealedSecret namespace | `cert-manager` |
| `cert-manager-issuer.sealed-secret.encryptedData.access-token` | Sealed DO API access token | _(required)_ |
| `cert-manager-issuer.cloudflare-secret.name` | SealedSecret name for Cloudflare API token | `cloudflare-dns` |
| `cert-manager-issuer.cloudflare-secret.namespace` | SealedSecret namespace | `cert-manager` |
| `cert-manager-issuer.cloudflare-secret.encryptedData.api-token` | Sealed Cloudflare API token | _(required)_ |

## Dependencies

| Chart | Version | Repository |
|---|---|---|
| cert-manager | v1.19.3 | https://charts.jetstack.io |
| cert-manager-issuer | 0.0.* | https://moreirodamian.github.io/helm-charts/ |

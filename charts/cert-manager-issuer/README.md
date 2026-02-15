# cert-manager-issuer

Creates Let's Encrypt ClusterIssuers for cert-manager. Supports an HTTP-01 issuer (`letsencrypt-prod`) and DNS-01 issuers for DigitalOcean (`letsencrypt-prod-dns`) and Cloudflare (`cloudflare-dns`). API tokens are managed via sealed-secrets.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.x
- cert-manager installed and running
- Sealed Secrets controller (for DNS provider tokens)

## Installation

This chart is typically installed as a dependency of the `cert-manager` wrapper chart. To install standalone:

```bash
helm dependency update
helm install cert-manager-issuer ./cert-manager-issuer -n cert-manager -f values.yaml
```

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `email` | Email for Let's Encrypt ACME registration | _(required)_ |
| `digitalocean.dns` | Enable DigitalOcean DNS-01 ClusterIssuer | `enabled` |
| `cloudflare.dns` | Enable Cloudflare DNS-01 ClusterIssuer | `true` |
| `sealed-secret.name` | SealedSecret name for DigitalOcean token | `digitalocean-dns` |
| `sealed-secret.namespace` | SealedSecret namespace | `cert-manager` |
| `sealed-secret.encryptedData.access-token` | Sealed DigitalOcean API access token | _(required)_ |
| `cloudflare-secret.name` | SealedSecret name for Cloudflare token | `cloudflare-dns` |
| `cloudflare-secret.namespace` | SealedSecret namespace | `cert-manager` |
| `cloudflare-secret.encryptedData.api-token` | Sealed Cloudflare API token | _(required)_ |

## Created Resources

| Resource | Name | Description |
|---|---|---|
| ClusterIssuer | `letsencrypt-prod` | HTTP-01 challenge via nginx ingress (always created) |
| ClusterIssuer | `letsencrypt-prod-dns` | DNS-01 challenge via DigitalOcean (when `digitalocean.dns` is truthy) |
| ClusterIssuer | `cloudflare-dns` | DNS-01 challenge via Cloudflare (when `cloudflare.dns` is truthy) |
| SealedSecret | `digitalocean-dns` | DigitalOcean API token (when `digitalocean.dns` is truthy) |
| SealedSecret | `cloudflare-dns` | Cloudflare API token (when `cloudflare.dns` is truthy) |

# eks-boostraping

ArgoCD-based bootstrap chart for AWS EKS clusters. Deploys infrastructure components as ArgoCD Application resources with automated sync, pruning, and self-healing. Each component is conditionally deployed only when its `version` value is set.

**Chart version:** 0.0.9

## Prerequisites

- AWS EKS cluster
- ArgoCD installed and running in the `argocd` namespace
- Helm 3+

## Installation

```bash
helm install eks-bootstrap ./charts/eks-boostraping \
  --set env=production \
  --set region=us-east-1 \
  --set clusterName=my-cluster
```

## Components

Each component is deployed as an ArgoCD Application when its `version` is set (non-null):

| Component | Description |
|---|---|
| `argo-rollouts` | Progressive delivery controller |
| `argo-rollouts-dashboard` | Argo Rollouts dashboard UI |
| `cluster-autoscaler` | Kubernetes cluster autoscaler |
| `ebs-csi-driver` | AWS EBS CSI driver for persistent volumes |
| `efs-csi-driver` | AWS EFS CSI driver for shared filesystems |
| `ingress-nginx` | NGINX ingress controller |
| `metrics-server` | Kubernetes metrics server |
| `prometheus` | Prometheus monitoring stack (with remote write support) |
| `promtail` | Log aggregation agent |

Note: `external-secrets` and `fluent-bit` templates exist but are currently commented out.

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `env` | Environment name (used in ArgoCD Application names) | `~` (required) |
| `region` | AWS region (used in ArgoCD Application names) | `~` (required) |
| `clusterName` | ArgoCD cluster destination name | `in-cluster` |
| `project` | ArgoCD project name | `infra` |
| `namespace` | Default target namespace for components | `infra` |
| `prometheus.remoteWrite.url` | Prometheus remote write URL | `~` |
| `prometheus.remoteWrite.secret.name` | Secret name for remote write credentials | `prometheus` |
| `prometheus.clusterName` | Cluster label for Prometheus metrics | `~` |
| `<component>.version` | Chart version to deploy (set to enable) | `~` (disabled) |
| `<component>.values` | Helm values passed to the component chart | `~` |

### Example

```yaml
env: prod
region: us-east-1
clusterName: in-cluster
project: infra
namespace: infra

argo-rollouts:
  version: "2.35.0"
  values:
    dashboard:
      enabled: true

ingress-nginx:
  version: "4.9.0"
  values:
    controller:
      replicaCount: 2

metrics-server:
  version: "3.12.0"
```

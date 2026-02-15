# generic-app

A versatile Helm chart for deploying applications on Kubernetes with support for Argo Rollouts (canary), standard Deployments, CronJobs, and migrations.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.x
- Argo Rollouts controller (if using rollout mode)
- Sealed Secrets controller (if using sealed secrets)

## Installation

```bash
helm install my-app generic-app -f values.yaml
```

## Configuration

### General

| Parameter | Description | Default |
|---|---|---|
| `name` | Application name | `example` |
| `deployEnv` | Deployment environment | `dev` |
| `region` | Deployment region | `us-east-1` |
| `revisionHistoryLimit` | Number of old ReplicaSets to retain | `10` |

### Deployment Strategy

| Parameter | Description | Default |
|---|---|---|
| `rollout` | Argo Rollout canary config. Set to `~` (null) to use a standard Deployment | `canary with 10%/50% steps` |
| `rollout.canary.maxUnavailable` | Max unavailable pods during rollout | `0` |
| `rollout.canary.steps` | Canary rollout steps | `setWeight 10 -> pause 10m -> setWeight 50 -> pause 10m` |
| `deployment.replicaCount` | Replica count (only when `rollout` is null) | `2` |

### Application

| Parameter | Description | Default |
|---|---|---|
| `app.image.registry` | Container image registry | `ecr` |
| `app.image.name` | Container image name | `~` |
| `app.image.tag` | Container image tag | `~` |
| `app.ports` | List of container ports | `[{name: http, containerPort: 8080, protocol: TCP}]` |
| `app.livenessProbe` | Liveness probe configuration | `{}` |
| `app.readinessProbe` | Readiness probe configuration | `{}` |
| `app.startupProbe` | Startup probe configuration | `{}` |
| `app.resources` | CPU/Memory resource requests/limits | `{}` |
| `app.env` | Environment variables | `{}` |
| `app.secrets` | Secret environment variables | `{}` |
| `app.envFrom` | EnvFrom sources | `[]` |
| `app.volumes` | Volume definitions | `[]` |
| `app.volumeMounts` | Volume mount definitions | `[]` |

### Service

| Parameter | Description | Default |
|---|---|---|
| `service.create` | Create a Service resource | `true` |
| `service.grpc` | Enable gRPC support | `false` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Target port on the container | `80` |
| `service.additionalPorts` | Additional service ports | `{}` |

### Ingress

| Parameter | Description | Default |
|---|---|---|
| `ingress.create` | Create an Ingress resource | `true` |
| `ingress.grpc` | Enable gRPC ingress | `false` |
| `ingress.letsencrypt` | Enable Let's Encrypt annotations | `false` |
| `ingress.annotations` | Ingress annotations | `[]` |
| `ingress.hosts` | Ingress hostnames | `[]` |
| `ingress.tls` | TLS configuration | `[]` |
| `customServices` | Additional custom Service resources | `[]` |
| `customIngress` | Additional custom Ingress resources | `[]` |

### Autoscaling and Availability

| Parameter | Description | Default |
|---|---|---|
| `hpa.create` | Create a HorizontalPodAutoscaler | `true` |
| `hpa.minReplicas` | Minimum replicas | `1` |
| `hpa.maxReplicas` | Maximum replicas | `5` |
| `hpa.cpuPercentage` | Target CPU utilization percentage | `70` |
| `pdb.enabled` | Create a PodDisruptionBudget | `false` |
| `pdb.minAvailable` | Minimum available pods | `1` |
| `networkPolicy.enabled` | Create a NetworkPolicy | `false` |
| `networkPolicy.ingress` | NetworkPolicy ingress rules | `[]` |
| `networkPolicy.egress` | NetworkPolicy egress rules | `[]` |

### Secrets

| Parameter | Description | Default |
|---|---|---|
| `sealedSecrets.enabled` | Create a SealedSecret resource | `true` |
| `sealedSecrets.encryptedData` | Encrypted key-value pairs | `{}` |
| `sealedSecrets.annotations` | SealedSecret annotations | `{"helm.sh/hook-weight": "-5"}` |
| `sealedSecrets.type` | Secret type | `{}` |
| `dockerSecret` | Docker registry pull secret configuration | `{}` |

### Migrations

| Parameter | Description | Default |
|---|---|---|
| `migrations.enabled` | Run a pre-install/pre-upgrade migration Job | `false` |
| `migrations.image` | Optional separate image for migrations (falls back to `app.image`) | `~` |

### CronJobs

| Parameter | Description | Default |
|---|---|---|
| `cron.enabled` | Create CronJob resources | `false` |
| `cron.successfulJobsHistoryLimit` | Successful job history limit | `1` |
| `cron.failedJobsHistoryLimit` | Failed job history limit | `2` |
| `cron.concurrencyPolicy` | Concurrency policy | `Allow` |
| `cron.ttlSecondsAfterFinished` | TTL for finished jobs | `60` |

### Service Account

| Parameter | Description | Default |
|---|---|---|
| `serviceAccount.create` | Create a ServiceAccount | `true` |
| `serviceAccount.annotations` | ServiceAccount annotations | `{}` |

### Testing

| Parameter | Description | Default |
|---|---|---|
| `testConnection.enabled` | Create a test connection pod | `true` |

# laravel

Multi-component Helm chart for deploying Laravel applications on Kubernetes. Bundles four subcharts that handle distinct responsibilities of a Laravel stack, plus optional SealedSecret support for encrypted secrets.

**Chart version:** 1.1.21

## Prerequisites

- Kubernetes 1.16+
- Helm 3+
- Container images built for your Laravel application (FPM, Nginx, CLI/Cron, Queue)
- sealed-secrets controller (if using the `sealed-secret` subchart)

## Installation

```bash
helm repo add moreirodamian https://moreirodamian.github.io/helm-charts/
helm repo update
helm install my-app moreirodamian/laravel -f values.yaml
```

## Architecture

The chart deploys up to five components, each independently enabled:

| Subchart | Version | Description | Condition |
|---|---|---|---|
| `fpm` | 0.1.8 | PHP-FPM application server with database migrations | Always deployed |
| `web-server` | 0.1.5 | Nginx reverse proxy with ingress support | Always deployed |
| `cron` | 0.1.4 | Laravel task scheduler (`schedule:run`) | `cron.create` |
| `queue` | 0.1.4 | Laravel queue worker (`queue:work`) | `queue.create` |
| `sealed-secret` | 0.1.x | Bitnami SealedSecret for encrypted secrets | `sealed-secret.create` |

## Configuration

### Global

| Parameter | Description | Default |
|---|---|---|
| `global.name` | Application name used across subcharts | `app` |
| `global.environment` | Environment identifier | `jose` |
| `global.namespace` | Global namespace override | `""` |
| `global.appVersion` | Application version tag for container images | `"1.16"` |
| `global.image.repository` | Container image repository | `nginx` |
| `global.imagePullSecrets` | Image pull secrets | `[]` |
| `global.dockerSecret.name` | Docker registry secret name | `dockerSecretName` |
| `global.dockerSecret.key` | Docker registry secret key | `dockerSecretKey` |

### FPM

| Parameter | Description | Default |
|---|---|---|
| `fpm.service.port` | PHP-FPM service port | `9000` |
| `fpm.autoscaling.enabled` | Enable HPA | `true` |
| `fpm.autoscaling.minReplicas` | Minimum replicas | `1` |
| `fpm.autoscaling.maxReplicas` | Maximum replicas | `100` |
| `fpm.autoscaling.targetCPUUtilizationPercentage` | CPU target for scaling | `80` |
| `fpm.deployment.resources` | CPU/memory requests and limits | `100m/128Mi` |
| `fpm.deployment.envFrom` | Environment variable sources (configmaps/secrets) | ConfigMap + Secret refs |
| `fpm.deployment.lifecycle` | Lifecycle hooks (postStart, preStop) | postStart + preStop sleep |
| `fpm.deployment.persistentVolumeClaim.enabled` | Enable PVC for shared storage | `false` |
| `fpm.deployment.persistentVolumeClaim.storageClassName` | PVC storage class | `nfs` |
| `fpm.deployment.persistentVolumeClaim.size` | PVC size | `100Mi` |
| `fpm.deployment.persistentVolumeClaim.mountPath` | PVC mount path | `/var/www/html/storage` |
| `fpm.migrations.enabled` | Run database migrations before deploy | `true` |
| `fpm.migrations.image.component` | Image component tag for migrations | `cli` |
| `fpm.image.component` | Image component tag for FPM | `fpm` |

### Web Server

| Parameter | Description | Default |
|---|---|---|
| `web-server.service.port` | Nginx service port | `80` |
| `web-server.ingress.enabled` | Enable ingress | `true` |
| `web-server.ingress.annotations` | Ingress annotations | nginx class, cert-manager issuer, proxy settings |
| `web-server.ingress.hosts` | Ingress host rules | `[]` |
| `web-server.ingress.tls` | TLS configuration | `[]` |
| `web-server.autoscaling.enabled` | Enable HPA | `true` |
| `web-server.deployment.resources` | CPU/memory requests and limits | `100m/128Mi` |
| `web-server.deployment.env` | Environment variables (e.g., FPM_HOST) | `[]` |

### Cron

| Parameter | Description | Default |
|---|---|---|
| `cron.create` | Deploy the cron subchart | `false` (condition) |
| `cron.deployment.resources` | CPU/memory requests and limits | `100m/128Mi` |
| `cron.deployment.envFrom` | Environment variable sources | ConfigMap + Secret refs |
| `cron.deployment.lifecycle` | Lifecycle hooks | postStart + preStop sleep |
| `cron.image.component` | Image component tag | `cron` |

### Queue

| Parameter | Description | Default |
|---|---|---|
| `queue.create` | Deploy the queue subchart | `false` (condition) |
| `queue.deployment.command` | Container command | `["php"]` |
| `queue.deployment.args` | Container args | `["artisan", "queue:work", "--queue=default"]` |
| `queue.deployment.resources` | CPU/memory requests and limits | `100m/128Mi` |
| `queue.deployment.envFrom` | Environment variable sources | ConfigMap + Secret refs |

### Sealed Secret

| Parameter | Description | Default |
|---|---|---|
| `sealed-secret.create` | Deploy the SealedSecret resource | `true` |
| `sealed-secret.name` | Name of the generated Kubernetes secret | `laravel-secrets` |
| `sealed-secret.type` | Secret type | `Opaque` |
| `sealed-secret.annotations` | SealedSecret annotations | cluster-wide, hook-weight |
| `sealed-secret.encryptedData` | Map of encrypted key/value pairs | `{}` |

### Example

```yaml
global:
  name: my-laravel-app
  environment: production
  appVersion: "1.0.0"
  image:
    repository: registry.example.com/my-app

fpm:
  deployment:
    resources:
      requests:
        cpu: 250m
        memory: 256Mi
    envFrom:
      - configMapRef:
          name: my-app-config
      - secretRef:
          name: laravel-secrets

web-server:
  ingress:
    enabled: true
    hosts:
      - host: app.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: app-tls
        hosts:
          - app.example.com
  deployment:
    env:
      - name: FPM_HOST
        value: my-laravel-app-fpm:9000

cron:
  create: true

queue:
  create: true
  deployment:
    args:
      - artisan
      - queue:work
      - --queue=default,emails

sealed-secret:
  create: true
  name: laravel-secrets
  encryptedData:
    APP_KEY: AgBY7...encrypted...
    DB_PASSWORD: AgBY7...encrypted...
```

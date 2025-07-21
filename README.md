# TinyLlama 1.1B Chat Deployment on K3s with ArgoCD

This project deploys the TinyLlama/TinyLlama-1.1B-Chat-v1.0 model on a Kubernetes cluster using K3s and ArgoCD for GitOps-based continuous deployment.

## Overview

TinyLlama is a compact 1.1B parameter language model that provides chat capabilities while being lightweight enough to run on resource-constrained environments. This deployment leverages K3s for a minimal Kubernetes footprint and ArgoCD for automated, declarative deployments.

## Prerequisites

- Linux server or virtual machine with at least 4GB RAM and 2 CPU cores
- Docker installed
- Git installed
- kubectl installed
- Minimum 10GB available disk space

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Git Repository │───▶│     ArgoCD      │───▶│   K3s Cluster   │
│                 │    │                 │    │                 │
│ - Manifests     │    │ - Sync Policy   │    │ - TinyLlama Pod │
│ - Configs       │    │ - Health Checks │    │ - Service       │
│ - Helm Charts   │    │ - Auto Deploy   │    │ - Ingress       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Quick Start

### 1. Install K3s

```bash
# Install K3s (single node)
curl -sfL https://get.k3s.io | sh -

# Verify installation
sudo k3s kubectl get nodes

# Copy kubeconfig for kubectl access
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
export KUBECONFIG=~/.kube/config
```

### 2. Install ArgoCD

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access ArgoCD UI (run in background)
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
```

### 3. Deploy TinyLlama Application

```bash
# Clone this repository
git clone <your-repo-url>
cd tinyllama-k3s-argocd

# Apply the ArgoCD application manifest
kubectl apply -f argocd/application.yaml

# Monitor deployment
kubectl get pods -n tinyllama -w
```

## Project Structure

```
.
├── README.md
├── argocd/
│   ├── application.yaml          # ArgoCD Application definition
│   └── project.yaml              # ArgoCD Project definition
├── k8s/
│   ├── namespace.yaml            # Kubernetes namespace
│   ├── deployment.yaml           # TinyLlama deployment
│   ├── service.yaml              # Kubernetes service
│   ├── ingress.yaml              # Ingress configuration
│   └── configmap.yaml            # Configuration settings
└── helm/                         # Optional Helm chart
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
```

## Configuration

### Environment Variables

The TinyLlama deployment supports the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `MODEL_NAME` | HuggingFace model identifier | `TinyLlama/TinyLlama-1.1B-Chat-v1.0` |
| `MAX_TOKENS` | Maximum tokens per response | `512` |
| `TEMPERATURE` | Sampling temperature | `0.7` |
| `PORT` | Service port | `8000` |

### Resource Requirements

```yaml
resources:
  requests:
    memory: "2Gi"
    cpu: "1000m"
  limits:
    memory: "4Gi"
    cpu: "2000m"
```

## Accessing the Application

### Via Port Forward (Development)

```bash
kubectl port-forward svc/tinyllama-service -n tinyllama 8000:8000
curl http://localhost:8000/chat -X POST -H "Content-Type: application/json" -d '{"message": "Hello!"}'
```

### Via Ingress (Production)

Update the ingress configuration in `k8s/ingress.yaml` with your domain:

```yaml
spec:
  rules:
  - host: tinyllama.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: tinyllama-service
            port:
              number: 8000
```

## ArgoCD Configuration

### Sync Policies

The application is configured with automatic sync enabled:

```yaml
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### Health Checks

Custom health checks ensure the TinyLlama service is responding correctly before marking the deployment as healthy.

## Monitoring and Troubleshooting

### Check Application Status

```bash
# ArgoCD application status
kubectl get application tinyllama -n argocd

# Pod status
kubectl get pods -n tinyllama

# Service endpoints
kubectl get endpoints -n tinyllama

# Logs
kubectl logs -f deployment/tinyllama-deployment -n tinyllama
```

### Common Issues

**Pod stuck in Pending state:**
- Check node resources: `kubectl describe nodes`
- Verify image pull: `kubectl describe pod <pod-name> -n tinyllama`

**Service not accessible:**
- Verify service endpoints: `kubectl get endpoints -n tinyllama`
- Check ingress configuration: `kubectl describe ingress -n tinyllama`

**ArgoCD sync failures:**
- Check application events: `kubectl describe application tinyllama -n argocd`
- Review ArgoCD logs: `kubectl logs -f deployment/argocd-application-controller -n argocd`

## Scaling

### Horizontal Pod Autoscaler

Enable HPA for automatic scaling based on CPU/memory usage:

```bash
kubectl autoscale deployment tinyllama-deployment --cpu-percent=70 --min=1 --max=5 -n tinyllama
```

### Manual Scaling

```bash
kubectl scale deployment tinyllama-deployment --replicas=3 -n tinyllama
```

## Security Considerations

- Enable RBAC for ArgoCD
- Use network policies to restrict pod communication
- Implement resource quotas and limits
- Regular security scanning of container images
- Enable audit logging in K3s

## Backup and Recovery

### Backup Configuration

```bash
# Backup K3s etcd
sudo k3s etcd-snapshot save backup-$(date +%Y%m%d-%H%M%S)

# Backup ArgoCD configuration
kubectl get applications -n argocd -o yaml > argocd-applications-backup.yaml
```

### Recovery

```bash
# Restore from etcd snapshot
sudo k3s server --cluster-init --cluster-reset --etcd-snapshot=backup-file
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Create an issue in this repository
- Check the ArgoCD documentation: https://argo-cd.readthedocs.io/
- Refer to K3s documentation: https://docs.k3s.io/

## Acknowledgments

- TinyLlama team for the excellent small language model
- ArgoCD community for GitOps tooling
- Rancher Labs for K3s lightweight Kubernetes
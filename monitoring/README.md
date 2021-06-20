# Monitoring (using Prometheus)

Prometheus deployment using HELM for the purpose of monitoring the whole cluster and services.

### Prerequisites
-   Kubernetes 1.16+
-   Helm 3+

## Usage

### Get Chart
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
helm repo update
```

###  Install Chart with custom values
```bash
helm install prom -f prom-values.yaml prometheus-community/prometheus
```

### Configuration


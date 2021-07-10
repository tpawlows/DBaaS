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

### Verify Prometheus server via port-forwarding
```bash
kubectl port-forward prom-prometheus-server-${release} 9090:9090
```
Then check in a browser on **http://127.0.0.1:9090** if you can access Prometheus server UI.

### Configuration
Here is the list of changed values of the Chart
| Parameter | Default | Updated |
|--|--|--|
| alertmanager.enabled| true | false |
|  |  |  |


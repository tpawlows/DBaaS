# Dashboards (with Grafana)

Grafana is an open-source platform for monitoring and observability. It help analyze logs from a large set of sources.

### Prerequisites

-   Kubernetes 1.16+
-   Helm 3+

## Usage

### Get Chart

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

### Install Chart with custom values
```bash
# set yourself a strong password in $STRONG_PASSWORD variable
helm install graf -f grafana-values.yaml --set adminPassword=$STRONG_PASSWORD grafana/grafana
```

### Verify Grafana server via port-forwarding
```bash
kubectl port-forward $GRAFANA_SERVICE 3000:3000
```
Then check in a browser on **[http://127.0.0.1:3000](http://127.0.0.1:3000)** if you can access Grafana.

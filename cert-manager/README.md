# cert-manager

Cert-manager manages TLS certificates so a connection between user and a web service is done via https.

### Prerequisites

-   Kubernetes 1.12+
-   Helm 3.1.0

## Usage

### Get Chart

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### Create cert-manager namespace
```bash
kubectl create ns cert-manager
```

### Install CRDs for cert-manager 
```bash
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.crds.yaml
```

### Install Chart in cert-manager namespace
```bash
helm install cert-manager  --namespace cert-manager jetstack/cert-manager
```

### Deploy ClusterIssuer
```bash
kubectl apply -f cluster-issuer.yaml 
```
### Deploy Certificate
```bash
kubectl apply -f common-cert.yaml 
```

# cert-manager

Cert-manager manages TLS certificates so a connection between user and a web service is done via https.

### Prerequisites

-   Kubernetes 1.12+
-   Helm 3.1.0

## Usage

### Get Chart

```bash
helm repo add jetstack https://charts.jetstack.io
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
### Deploy Certificate for telemetry and pgadmin
```bash
kubectl apply -f common-cert.yaml 
kubectl apply -f pgadmin-cert.yaml 
```
### Setup TLS for Postgres Cluster
A PGO-managed Postgres needs at least 2 certificates:
- One certificate is for the Postgres cluster itself and is used to both identify the cluster and encrypt communications
- Second certificate is used for replication authentication

More detailed information: [using-cert-manager-to-deploy-tls-for-postgres-on-kubernetes](https://blog.crunchydata.com/blog/using-cert-manager-to-deploy-tls-for-postgres-on-kubernetes)
```bash
git clone git@github.com:tpawlows/postgres-operator-examples.git
# It will deploy:
# - self-signed Certificate Isuuer
# - common certificate authority (CA) certificate
# - CA certificate issuer using the generated CA certificate
kubectl apply -k kustomize/certmanager/certman

# Deploy first certificate
kubectl apply -f cert-manager/hippo-cert.yaml

# Replication certificate WIP
```

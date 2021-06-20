# kops-nginx-ingress-controller

Nginx ingress controller for accepting inbound traffic to cluster's service using http/https.

# Prerequisites

### Install HELM
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```
### Have k8s up & running
To create kubernetes cluster using kOps follow instructions provided [here](https://github.com/tpawlows/kops-create-cluster)
# Usage
### Get Chart
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```
### Create ingress namespace (optional)
```bash
kubectl create namespace ingress
```
### Install Chart with custom values
```bash
helm install nginx-ingress-controller -f nginx-ingress-values.yaml  -n ingress ingress-nginx/ingress-nginx
```
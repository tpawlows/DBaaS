#!/bin/bash
# This scripts runs every command necessary for building 
# Postrgres DbaaS, that is run on top of k8s cluster on AWS

if [ $# -eq 0 ]; then
    echo "Please provide a path to the root directory of DBaaS repository."
    echo "exiting.."
    exit 1
fi

# Go to root dir of dbaas repository
ROOT_DIR=$1
cd $ROOT_DIR

# Update HELM repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Create k8s cluster 
kops-create-cluster/private-single-az-cluster/private-single-az-cluster.sh k8s.retipuj.com retipuj.com 
sleep 20
# Deploy NGINX Ingress Controller
kubectl create ns ingress
helm install nginx-ingress-controller -f nginx-ingress-controller/nginx-ingress-values.yaml  -n ingress ingress-nginx/ingress-nginx
sleep 40

# Deploy Ingress
kubectl apply -f ingress/ingress.yaml  
sleep 40

# Deploy cert-manager
kubectl create ns cert-manager
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.crds.yaml
helm install cert-manager  --namespace cert-manager jetstack/cert-manager
sleep 120 

# Deploy external-dns
export AllowExternalDNSUpdates=$(aws iam list-policies | grep  AllowExternalDNSUpdates | grep Arn | cut -d "\"" -f4)
aws iam attach-role-policy --role-name nodes.k8s.retipuj.com --policy-arn $AllowExternalDNSUpdates
sleep 60 
export hostedZoneID=$(aws route53 list-hosted-zones-by-name --output json --dns-name "retipuj.com" | jq -r '.HostedZones[0].Id')
helm install -f external-dns/external-dns-values.yaml --set txtOwnerId=$hostedZoneID external-dns bitnami/external-dns
sleep 60

# Deploy monitoring and daashboards
helm install prom -f monitoring/prom-values.yaml prometheus-community/prometheus
# an example password; change
export STRONG_PASSWORD=k0psP@S456
helm install graf -f dashboards/grafana-values.yaml --set adminPassword=$STRONG_PASSWORD grafana/grafana

# Deploy ClusterIssuer and Certificate for exposed services
kubectl apply -f cert-manager/cluster-issuer.yaml 
kubectl apply -f cert-manager/common-cert.yaml

echo "Cluster k8s.retipuj.com has been created!"
echo "Available services:"
echo "  prometheus.k8s.retipuj.com"
echo "  grafana.k8s.retipuj.com"

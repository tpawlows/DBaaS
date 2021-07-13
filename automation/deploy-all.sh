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

# Create namespace for Postgres
kubectl create ns pgo

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

# Deploy monitoring and dashboards
helm install prom -f monitoring/prom-values.yaml prometheus-community/prometheus
# an example password; change
export STRONG_PASSWORD=k0psP@S456
helm install graf -f dashboards/grafana-values.yaml --set adminPassword=$STRONG_PASSWORD grafana/grafana

# Deploy ClusterIssuer and Certificate for exposed services
kubectl apply -f cert-manager/cluster-issuer.yaml 
kubectl apply -f cert-manager/common-cert.yaml
kubectl apply -f cert-manager/pgadmin-cert.yaml 

# Create Ingress for pgAdmin4
kubectl apply -f pgadmin-ingress.yaml

## Setup TLS for Postgres Cluster

sudo cp /usr/lib/ssl/openssl.cnf .
sudo chmod 777 openssl.cnf 
sed -i 's/# req_extensions = v3_req/req_extensions = v3_req/g' openssl.cnf

# Generate CA
openssl req \
-x509 \
-nodes \
-newkey ec \
-pkeyopt ec_paramgen_curve:prime256v1 \
-pkeyopt ec_param_enc:named_curve \
-sha384 \
-keyout ca.key \
-out ca.crt \
-days 3650 \
-extensions v3_ca \
-subj "/CN=*"

# Generate the Certificate Signing Request (CSR)
openssl req \
-new \
-newkey ec \
-nodes \
-pkeyopt ec_paramgen_curve:prime256v1 \
-pkeyopt ec_param_enc:named_curve \
-sha384 \
-keyout server.key \
-out server.csr \
-days 365 \
-subj "/CN=hippo.pgo"

# Create the server Certificate
openssl x509 \
-req \
-in server.csr \
-days 365 \
-CA ca.crt \
-CAkey ca.key \
-CAcreateserial \
-sha384 \
-extfile openssl.cnf \
-extensions v3_req \
-out server.crt

# Create kubernets secrets for the CA and the server certificate
kubectl create secret generic -n pgo postgres-ca --from-file=ca.crt=ca.crt
kubectl create secret tls -n pgo hippo.tls --key=server.key --cert=server.crt

# Create Postgresql Operator in pgo namespace
kubectl apply -f crunchy-postrgresql-operator/postgres-operator.yml
sleep 120

# Change postgres-operator service from ClusterIP to LoadBalancer
kubectl -n pgo patch svc postgres-operator --type='json' -p '[{"op":"replace","path":"/spec/type","value":"LoadBalancer"}]'
sleep 120

# # Add annotation of pgo for external-dns
kubectl -n pgo annotate service postgres-operator "external-dns.alpha.kubernetes.io/hostname=pgo.k8s.retipuj.com"

# Setup PGO client
curl https://raw.githubusercontent.com/CrunchyData/postgres-operator/v4.7.0/installers/kubectl/client-setup.sh > client-setup.sh
chmod +x client-setup.sh
./client-setup.sh

# # Create PostgreSQL cluster called hippo
pgo create cluster -n pgo --metrics --tls-only --server-ca-secret=postgres-ca --server-tls-secret=hippo.tls --service-type=LoadBalancer --username $PGUSER --password $PGPASSWORD hippo 
sleep 120

# Add annotation of hippo cluster for external-dns
kubectl -n pgo annotate service hippo  "external-dns.alpha.kubernetes.io/hostname=hippo.k8s.retipuj.com"

# Connect postgres-exporter to prometheus
kubectl -n pgo annotate service hippo  "prometheus.io/scrape=true"
kubectl -n pgo annotate service hippo  "prometheus.io/port=9187"

# Deploy pgAdmin 4 service
pgo create pgadmin -n pgo hippo

echo "Cluster k8s.retipuj.com has been created!"
echo "Available services:"
echo "  prometheus.k8s.retipuj.com"
echo "  grafana.k8s.retipuj.com"
echo "  pgo.k8s.retipuj.com"
echo "  hippo.k8s.retipuj.com"
echo "  pgadmin.k8s.retipuj.com"


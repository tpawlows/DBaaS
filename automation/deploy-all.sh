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
setup_helm() {

    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add jetstack https://charts.jetstack.io
    helm repo update

}

# Create cluster configuration, store it to s3,
# then deploy it on ec2 instances on AWS.
deploy_k8_cluster() {

    # Create and save configuration to s3
    kops create cluster \
	    --name=k8s.retipuj.com \
	    --dns-zone=retipuj.com \
	    --zones="eu-north-1a" \
	    --cloud=aws \
	    --node-count=1 \
	    --master-volume-size=32 \
	    --node-volume-size=32 \
	    --topology=private \
	    --networking=kube-router 
    echo "Cluster configuration saved to: $KOPS_STATE_STORE"

    # Create actual cluster on AWS
    kops update cluster k8s.retipuj.com --yes --admin

    # Wait for kOps to create cluster (about 12 min) 
    kops validate cluster --wait 15m

}

deploy_ingress() {

    # Ingress
    kubectl apply -f ingress/ingress.yaml 

    # NGINX Ingress Controller
    kubectl create ns ingress
    helm install nginx-ingress-controller -f nginx-ingress-controller/nginx-ingress-values.yaml  -n ingress ingress-nginx/ingress-nginx

}

deploy_cert_manager() {

    kubectl create ns cert-manager
    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.crds.yaml
    helm install cert-manager --namespace cert-manager jetstack/cert-manager

    # Deploy ClusterIssuer and Certificate for exposed services
    kubectl apply -f cert-manager/cluster-issuer.yaml 
    kubectl apply -f cert-manager/common-cert.yaml
    kubectl apply -f cert-manager/pgadmin-cert.yaml 

    # Create Ingress for pgAdmin4
    kubectl apply -f pgadmin-ingress.yaml

}

deploy_external_dns() {

    # Attach policy for updating DNS server for k8s's worker machines group
    export AllowExternalDNSUpdates=$(aws iam list-policies | grep  AllowExternalDNSUpdates | grep Arn | cut -d "\"" -f4)
    aws iam attach-role-policy --role-name nodes.k8s.retipuj.com --policy-arn $AllowExternalDNSUpdates
    export hostedZoneID=$(aws route53 list-hosted-zones-by-name --output json --dns-name "retipuj.com" | jq -r '.HostedZones[0].Id')
    helm install -f external-dns/external-dns-values.yaml --set txtOwnerId=$hostedZoneID external-dns bitnami/external-dns

}

deploy_monitoring() {
    
    # Deploy monitoring and dashboards
    helm install prom -f monitoring/prom-values.yaml prometheus-community/prometheus
    
    # an example password; change
    export GRAFANA_PASSWORD=k0psP@S456
    helm install graf -f dashboards/grafana-values.yaml --set adminPassword=$GRAFANA_PASSWORD grafana/grafana

}

setup_tls_for_postgres() {

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

}

deploy_pgo() {
    
    # Create namespace for Postgres
    kubectl create ns pgo

    # Create Postgresql Operator in pgo namespace
    kubectl apply -f crunchy-postrgresql-operator/postgres-operator.yml
    sleep 120

    # Change postgres-operator service from ClusterIP to LoadBalancer
    kubectl -n pgo patch svc postgres-operator --type='json' -p '[{"op":"replace","path":"/spec/type","value":"LoadBalancer"}]'
    sleep 120

    # # Add annotation of pgo for external-dns
    kubectl -n pgo annotate service postgres-operator "external-dns.alpha.kubernetes.io/hostname=pgo.k8s.retipuj.com"
    sleep 120

}

setup_pgo() {
    
    curl https://raw.githubusercontent.com/CrunchyData/postgres-operator/v4.7.0/installers/kubectl/client-setup.sh > client-setup.sh
    chmod +x client-setup.sh
    ./client-setup.sh

}

deploy_postgres_cluster() {
    
    # Create PostgreSQL cluster called hippo
    pgo create cluster -n pgo --metrics --tls-only --server-ca-secret=postgres-ca --server-tls-secret=hippo.tls --service-type=LoadBalancer --username $PGUSER --password $PGPASSWORD hippo 
    # Add annotation of hippo cluster for external-dns
    kubectl -n pgo annotate service hippo  "external-dns.alpha.kubernetes.io/hostname=hippo.k8s.retipuj.com"

    # Connect postgres-exporter to prometheus
    kubectl -n pgo annotate service hippo  "prometheus.io/scrape=true"
    kubectl -n pgo annotate service hippo  "prometheus.io/port=9187"

    # Deploy pgAdmin 4 service
    pgo create pgadmin -n pgo hippo

}


setup_helm
deploy_k8_cluster
deploy_ingress
deploy_cert_manager
deploy_external_dns
deploy_monitoring
setup_tls_for_postgres
deploy_postgres_cluster

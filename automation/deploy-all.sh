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
    kops create -f kops-create-cluster/ha-cluster/ha-cluster.yaml 
    echo "Cluster configuration saved to: $KOPS_STATE_STORE"
    kops create secret --name $CLUSTER sshpublickey admin -i ~/.ssh/id_rsa.pub

    # Create actual cluster on AWS
    kops update cluster k8s.retipuj.com --yes --admin

    # Wait for kOps to create cluster (about 12 min) 
    kops validate cluster --wait 15m
    # might be a problem with kubecfg
    kops export kubecfg --admin
    kops validate cluster --wait 15m
}

create_namespaces() {
    kubectl create ns ingress
    kubectl create ns cert-manager
    # Postgres Operator 
    kubectl create ns pgo
}

deploy_ingress_controller() {
    # NGINX Ingress Controller
    helm install nginx-ingress-controller -f nginx-ingress-controller/nginx-ingress-values.yaml -n ingress ingress-nginx/ingress-nginx
}

deploy_cert_manager() {

    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.crds.yaml
    helm install cert-manager --namespace cert-manager jetstack/cert-manager

    # Deploy ClusterIssuer and Certificate for exposed services
    kubectl apply -f cert-manager/cluster-issuer.yaml 
    kubectl apply -f cert-manager/monitoring-cert.yaml
    kubectl apply -f cert-manager/pgadmin-cert.yaml 

}

deploy_external_dns() {

    # Attach policy for updating DNS server for k8s's worker machines group
    export AllowExternalDNSUpdates=$(aws iam list-policies | grep  AllowExternalDNSUpdates | grep Arn | cut -d "\"" -f4)
    aws iam attach-role-policy --role-name nodes.k8s.retipuj.com --policy-arn $AllowExternalDNSUpdates
    export hostedZoneID=$(aws route53 list-hosted-zones-by-name --output json --dns-name "retipuj.com" | jq -r '.HostedZones[0].Id')
    helm install -f external-dns/external-dns-values.yaml --set txtOwnerId=$hostedZoneID external-dns bitnami/external-dns

}

deploy_monitoring() {
    
    # Deploy Ingress for monitoring
    kubectl apply -f ingress/monitoring-ingress.yaml 

    # Deploy monitoring and dashboards
    helm install prom -f monitoring/prom-values.yaml prometheus-community/prometheus
    
    # an example password; change
    export GRAFANA_PASSWORD=k0psP@S456
    helm install graf -f dashboards/grafana-values.yaml --set adminPassword=$GRAFANA_PASSWORD grafana/grafana

}


setup_tls_for_postgres() {

    # Setup secure conections for postgres cluster.
    # For more information, please refer to:
    # https://blog.crunchydata.com/blog/using-cert-manager-to-deploy-tls-for-postgres-on-kubernetes
        
    git clone https://github.com/tpawlows/postgres-operator-examples.git
    
    # deploy: 
    # - self-signed Certificate Isuuer
    # - common certificate authority (CA) certificate
    # - CA certificate issuer using the generated CA certificate
    kubectl apply -k postgres-operator-examples/kustomize/certmanager/certman
    
    # deploy certificate for Postgres Cluster
    kubectl apply -f cert-manager/hippo-cert.yaml 
    # and replicas
    # TODO

}

deploy_pgo() {

    # Create Postgresql Operator in pgo namespace
    kubectl apply -f crunchy-postrgresql-operator/postgres-operator.yml
    sleep 120

    # Change postgres-operator service from ClusterIP to LoadBalancer
    kubectl -n pgo patch svc postgres-operator --type='json' -p '[{"op":"replace","path":"/spec/type","value":"LoadBalancer"}]'
    sleep 5

    # Add annotation of pgo for external-dns
    kubectl -n pgo annotate service postgres-operator "external-dns.alpha.kubernetes.io/hostname=pgo.k8s.retipuj.com"
    sleep 120

}

setup_pgo() {
    
    curl https://raw.githubusercontent.com/CrunchyData/postgres-operator/v4.7.0/installers/kubectl/client-setup.sh > client-setup.sh
    chmod +x client-setup.sh
    ./client-setup.sh

}

deploy_postgres_cluster() {

     tries_left=3

    # sometimes pgo client is unable to connect to apiserver
    # It is often connected to DNS server error, in case of error
    # set nameserver to 8.8.8.8 in etc/resolv.conf
    while [[ $tries_left -gt 0 ]]
    do
        pgo_error=$(pgo version | tail -1 | grep  "^Error")
        if [ -z "$pgo_error" ]; then

            # Create PostgreSQL cluster called hippo
            pgo create cluster -n pgo --metrics --tls-only                                          \
                --server-ca-secret=hippo-tls --server-tls-secret=hippo-tls                          \
                --service-type=LoadBalancer --username $PGUSER --password $PGPASSWORD               \
                --pod-anti-affinity=preferred --node-label=kops.k8s.io/instancegroup=hippo-nodes    \
                --node-affinity-type=required --toleration=dedicated=hippo-cluster:NoSchedule hippo

            # Add annotation of hippo cluster for external-dns
            kubectl -n pgo annotate service hippo  "external-dns.alpha.kubernetes.io/hostname=hippo.k8s.retipuj.com"

            # Connect postgres-exporter to prometheus
            kubectl -n pgo annotate service hippo  "prometheus.io/scrape=true"
            kubectl -n pgo annotate service hippo  "prometheus.io/port=9187"

            # Deploy pgAdmin 4 service
            pgo create pgadmin -n pgo hippo

            # Create Ingress for pgAdmin4
            kubectl apply -f ingress/pgadmin-ingress.yaml

            break
        else
            tries_left=$((tries_left-1))
            >&2 echo "Error: could not deploy postgres Cluster"
            sleep 5
        fi
    done
}

setup_helm
deploy_k8_cluster
sleep 60 # let's give cluster some time to be sure it's ready
create_namespaces
deploy_ingress_controller
deploy_cert_manager
deploy_external_dns
deploy_monitoring
setup_tls_for_postgres
deploy_pgo
setup_pgo
deploy_postgres_cluster

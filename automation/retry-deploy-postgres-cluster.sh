#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Please provide a path to the root directory of DBaaS repository."
    echo "exiting.."
    exit 1
fi

# Go to root dir of dbaas repository
ROOT_DIR=$1
cd $ROOT_DIR


tries_left=3
# sometimes pgo client is unable to connect to apiserver
# It is often connected to DNS server error, in case of error
# set nameserver to 8.8.8.8 in etc/resolv.conf
while [[ $tries_left -gt 0 ]]
do
    pgo_error=$(pgo version | tail -1 | grep  "^Error")
    if [ -z "$pgo_error" ]; then

        # Create secret for configuring more max_connections
        kubectl -n pgo create configmap hippo-custom-config --from-file=crunchy-postrgresql-operator/postgres-ha.yaml

        # Create PostgreSQL cluster called hippo
        pgo create cluster -n pgo --metrics --replica-count=1 --pvc-size 10Gi --custom-config=hippo-custom-config   \
            --service-type=ClusterIP --username $PGUSER --password $PGPASSWORD                                      \
            --pod-anti-affinity=preferred --node-label=kops.k8s.io/instancegroup=hippo-nodes                        \
            --node-affinity-type=required --toleration=dedicated=hippo-cluster:NoSchedule hippo                     \
            # --tls-only --server-ca-secret=hippo-tls --server-tls-secret=hippo-tls                                 \
            # --service-type=LoadBalancer
            
        # Add annotation of hippo cluster for external-dns
        # kubectl -n pgo annotate service hippo  "external-dns.alpha.kubernetes.io/hostname=hippo.k8s.retipuj.com"

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

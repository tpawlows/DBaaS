#!/bin/bash
# This scripts runs every command necessary for destroying 
# whole DbaaS and that is run on top of k8s cluster on AWS

if [ $# -eq 0 ]; then
    echo "Please provide a path to the root directory of DBaaS repository."
    echo "exiting.."
    exit 1
fi

# Go to root dir of dbaas repository
ROOT_DIR=$1
cd $ROOT_DIR

pgo delete -n pgo pgadmin hippo --no-prompt
pgo delete cluster hippo --no-prompt
kubectl delete -f crunchy-postrgresql-operator/postgres-operator.yml

helm uninstall graf
helm uninstall prom
helm uninstall external-dns 
helm uninstall cert-manager -n cert-manager
helm uninstall nginx-ingress-controller -n ingress
kops delete cluster k8s.retipuj.com --yes
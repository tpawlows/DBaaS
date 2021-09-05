#!/bin/bash
# Create certificates (hippo-tls, postgres-ca) for Postgres Cluster (Hippo) 
# and dploy the information to k8s cluster in pgo namespace.

if [ $# -eq 0 ]; then
    echo "Please provide a path to the root directory of DBaaS repository."
    echo "exiting.."
    exit 1
fi

# Go to root dir of dbaas repository
ROOT_DIR=$1
cd $ROOT_DIR

mkates/ca.crt \
    -days 3650 \
    -extensions v3_ca \
    -subj "/CN=*"

# Generate the Certificate Signing Request (CSR)
openssl req \
    -new \
    -newkey ec \
    -nodes \dir certificates
    sudo cp /usr/lib/ssl/openssl.cnf certificates/
    sudo chmod 777 certificates/openssl.cnf 
    sed -i 's/# req_extensions = v3_req/req_extensions = v3_req/g' certificates/openssl.cnf

# Generate CA
openssl req \
    -x509 \
    -nodes \
    -newkey ec \
    -pkeyopt ec_paramgen_curve:prime256v1 \
    -pkeyopt ec_param_enc:named_curve \
    -sha384 \
    -keyout certificates/ca.key \
    -out certific
    -pkeyopt ec_paramgen_curve:prime256v1 \
    -pkeyopt ec_param_enc:named_curve \
    -sha384 \
    -keyout certificates/server.key \
    -out certificates/server.csr \
    -days 365 \
    -subj "/CN=hippo.pgo"

# Create the server Certificate
openssl x509 \
    -req \
    -in certificates/server.csr \
    -days 365 \
    -CA certificates/ca.crt \
    -CAkey certificates/ca.key \
    -CAcreateserial \
    -sha384 \
    -extfile certificates/openssl.cnf \
    -extensions v3_req \
    -out certificates/server.crt

# Create kubernets secrets for the CA and the server certificate
kubectl create secret generic -n pgo postgres-ca --from-file=ca.crt=certificates/ca.crt
kubectl create secret tls -n pgo hippo-tls --key=certificates/server.key --cert=certificates/server.crt

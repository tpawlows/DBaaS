# Crunchy PostgreSQL for Kubernetes
Enterprise open source PostgreSQL-as-a-Service

## Pre-installation
Create a namespace
```bash
export PGO_NAMESPACE=pgo
kubectl create namespace "$PGO_NAMESPACE"
```
## Installation
Install PGO: the PostgreSQL Operator
```bash
kubectl apply -f https://raw.githubusercontent.com/CrunchyData/postgres-operator/v4.7.0/installers/kubectl/postgres-operator.yml
```
Install the pgo client
```bash
curl https://raw.githubusercontent.com/CrunchyData/postgres-operator/v4.7.0/installers/kubectl/client-setup.sh > client-setup.sh
chmod +x client-setup.sh
./client-setup.sh
```
Add to .bashrc
```bash
export PATH=/home/$USER/.pgo/pgo:$PATH
export PGOUSER=/home/$USER/.pgo/pgo/pgouser
export PGO_CA_CERT=/home/$USER/.pgo/pgo/client.crt
export PGO_CLIENT_CERT=/home/$USER/.pgo/pgo/client.crt
export PGO_CLIENT_KEY=/home/$USER/.pgo/pgo/client.key
export PGO_NAMESPACE=pgo
```

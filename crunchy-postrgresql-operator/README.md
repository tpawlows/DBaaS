# Crunchy PostgreSQL for Kubernetes
Enterprise open source PostgreSQL-as-a-Service.
Version: 4.7.0

## Pre-installation
### Install the pgo (PostgreSQL Operator) client
```bash
curl https://raw.githubusercontent.com/CrunchyData/postgres-operator/v4.7.0/installers/kubectl/client-setup.sh > client-setup.sh
chmod +x client-setup.sh
./client-setup.sh
```
### Create a namespace
```bash
export PGO_NAMESPACE=pgo
kubectl create namespace "$PGO_NAMESPACE"
Install the pgo client
```
### Add important environment variables to .bashrc.
```bash
cat <<EOF >> ~/.bashrc
export PGOUSER="${HOME?}/.pgo/pgo/pgouser"
export PGO_CA_CERT="${HOME?}/.pgo/pgo/client.crt"
export PGO_CLIENT_CERT="${HOME?}/.pgo/pgo/client.crt"
export PGO_CLIENT_KEY="${HOME?}/.pgo/pgo/client.key"
# DNS of Postgres Operator
export PGO_APISERVER_URL='https://pgo.k8s.retipuj.com:8443'
export PGO_NAMESPACE=pgo
export PATH=/home/$USER/.pgo/pgo:$PATH
EOF
```
### Apply changes
```bash
source ~.bashrc
```

## Installation
### Install PGO: the PostgreSQL Operator
```bash
kubectl apply -f https://raw.githubusercontent.com/CrunchyData/postgres-operator/v4.7.0/installers/kubectl/postgres-operator.yml
```
### Create DNS record for PostgreSQL Operator
The address of PGO will be pgo.k8s.retipuj.com
```bash
TODO add entry to pgo service 
```
### Create PostgreSQL cluster
The PostgreSQL cluster will:
- be named **hippo** (the same name as demo cluster in official guides and tutorials)
- have Prometheus exporter enabled
- have TLS connection enabled and restricted to secure connections only
- be available through DNS record: hippo.k8s.retipuj.com 
	- for connections for tools like psql and other Postgres clients.
- be deployed with pgAdmin 4, which is a graphical tool to manage PostgreSQL database from a web browser.
	- pgAdmin 4 will e available through DNS record: pgadmin4.k8s.retipuj.com
	- Connection will be secured using TLS

```bash
pgo create cluster -n pgo --metrics --service-type=LoadBalancer hippo
```
### Save displayed User and Password to environment variables
```bash
# example
export PGUSER=testuser
export PGPASSWORD="=4K2C?=RRp.2QiN>0{nO{DHqa"
```

### Deploy pgAdmin 4 service
```bash
pgo create pgadmin -n pgo hippo

```

### Create DNS record for deployed PostgreSQL Cluster
The address of PostgreSQL Cluster will be hippo.k8s.retipuj.com
```bash
TODO
```

### Create DNS record for pgAdmin 4
The address of pgAdmin4 will be pgadmin4.k8s.retipuj.com
```bash
TODO
```

## Validation

### Test cluster
```bash
pgo test -n pgo hippo
```
### Show information about cluster
```bash
pgo show cluster -n pgo
```
### Show cluster's users
```bash
pgo show user -n pgo hippo
```
# TLS for Postgres cluster
This readme provides instructions for creating CA certificates for Postgres cluster created using Crunchy's Postgres Operator.
For more detailed information please read articles below as this steps are based on this articles:
- [access.crunchydata.com/documentation/postgres-operator/4.7.0/tutorial/tls/](https://access.crunchydata.com/documentation/postgres-operator/4.7.0/tutorial/tls/)
- [blog.crunchydata.com/blog/tls-postgres--opkubernetesenssl](https://blog.crunchydata.com/blog/tls-postgres-kubernetes-openssl)
- [blog.crunchydata.com/blog/set-up-tls-for-postgresql-in-kubernetes](https://blog.crunchydata.com/blog/set-up-tls-for-postgresql-in-kubernetes)
## Set up TLS for Your Postgres Cluster
-  Copy openssl.cnf to your working directory
On Ubuntu 20.04 LTS openssl.cnf is located in /usr/lib/ssl directory.
```bash
sudo cp /usr/lib/ssl/openssl.cnf .
```
- Edit copied config:
	- uncomment x509_extensions and set it to v3_ca
	- uncomment req_extensions and set it to v3_req

- Generate the Certificate Authority (CA)
```bash
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
```
- Generate the Certificate Signing Request (CSR)
```bash
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
```
- Create the server Certificate
```bash
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
```
- Create kubernets secrets for the CA and the server certificate
```bash
kubectl create secret generic -n pgo postgres-ca --from-file=ca.crt=ca.crt
kubectl create secret tls -n pgo hippo.tls --key=server.key --cert=server.crt
```

Now everything is set up and ready for deployment of Postgres Cluster with enabled TLS. To create Postgres Cluster with TLS you have to specify parameters: **--tls-only**, **--server-ca-secret** and **--server-tls-secret**
Example:
```bash
pgo create cluster -n pgo --tls-only --server-ca-secret=postgres-ca --server-tls-secret=hippo.tls --service-type=LoadBalancer hippo
```
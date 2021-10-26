# pgpool-II
Pgpool-II is a middleware that works between PostgreSQL servers and a PostgreSQL database client. It is distributed under a license similar to BSD and MIT. It provides the following features.
-   **Connection Pooling**
-   **Replication**
-   **Load Balancing**
-   **Limiting Exceeding Connections**
-   **Watchdog**
-   **In Memory Query Cache**

### Deploy pgpool
```bash
kubectl apply -f pgpool/pgpool_deploy.yaml -f pgpool/pgpool_service.yaml
```

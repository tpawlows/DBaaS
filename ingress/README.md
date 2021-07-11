# ingress

### Usage
```bash
# ingress for default namespace (monitoring and dashboards)
kubectl apply -f ingress.yaml  
# ingress for pgAdmin4 in pgo namespace
kubectl -n pgo apply -f pgadmin-ingress.yaml 
```

## notes
Remember to deploy ingress in the same namespace as services you want to expose.



kubectl create secret generic backend-secret --from-literal=DB_USERNAME=root --from-literal=DB_PASSWORD=123456 -n backend --dry-run=client -o yaml

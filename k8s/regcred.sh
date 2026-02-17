kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=./credentials.json \
    --type=kubernetes.io/dockerconfigjson \
    --namespace=database \
    --dry-run=client \
    -o yaml > regcred.yaml
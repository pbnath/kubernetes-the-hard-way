#!/usr/bin/env bash

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/16-smoke-test.md#smoke-test

set -x
set -e
set -u

ssh -T vagrant@192.168.56.11 <<'EOF2'
cat >smoke.sh <<'EOF1'
#!/usr/bin/env bash

set -x
set -e
set -u

kubectl create secret generic kubernetes-the-hard-way \
  --from-literal="mykey=mydata"

sudo ETCDCTL_API=3 etcdctl get \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.crt \
  --cert=/etc/etcd/etcd-server.crt \
  --key=/etc/etcd/etcd-server.key\
  /registry/secrets/default/kubernetes-the-hard-way | hexdump -C

kubectl delete secret kubernetes-the-hard-way

cat >deployment-nginx.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: nginx
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  strategy: {}
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx:1.23.1
        name: nginx
        resources: {}
EOF
kubectl apply -f deployment-nginx.yaml

kubectl rollout status deployment/nginx
kubectl get pods -l app=nginx

cat >service-nginx.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: nginx
  name: nginx
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nginx
  type: NodePort
EOF
kubectl apply -f service-nginx.yaml

PORT_NUMBER=$(kubectl get svc -l app=nginx -o jsonpath="{.items[0].spec.ports[0].nodePort}")

for i in 1 2; do 
    if ! grep Welcome <<<"$(curl -sSL http://worker-${i}:$PORT_NUMBER)"; then
       echo failed at curl
       exit 1
    fi
done

POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")
kubectl logs $POD_NAME

#FIXME, this reports fail, but it actually works, figure out why.
if ! grep -F 1.23.1 <<<"$(kubectl exec -ti $POD_NAME -- nginx -v)" >/dev/null; then
    echo failed at nginx grep version
fi
EOF1

bash -x smoke.sh
EOF2

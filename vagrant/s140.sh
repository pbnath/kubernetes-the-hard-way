#!/usr/bin/env bash

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/12-configuring-kubectl.md

set -x
set -e
set -u

ssh -T vagrant@192.168.56.11 <<'EOF1'
cat >kubectl_config.sh <<'EOF'
#!/usr/bin/env bash

set -x
set -e
set -u

LOADBALANCER=$(dig +short loadbalancer)

{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${LOADBALANCER}:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key

  kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

  kubectl config use-context kubernetes-the-hard-way
}

kubectl get componentstatuses
kubectl get nodes
EOF
bash -x kubectl_config.sh
EOF1

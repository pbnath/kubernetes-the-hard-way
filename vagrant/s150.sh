#!/usr/bin/env bash

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/13-configure-pod-networking.md#provisioning-pod-network

set -x
set -e
set -u

ssh -T vagrant@192.168.56.11 <<'EOF1'
cat >weave_config.sh <<'EOF'
#!/usr/bin/env bash

set -x
set -e
set -u

kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s-1.11.yaml --wait
kubectl -n kube-system rollout status daemonset/weave-net
kubectl get pods -n kube-system
kubectl get nodes
EOF
bash -x weave_config.sh
EOF1

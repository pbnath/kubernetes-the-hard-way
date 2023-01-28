#!/usr/bin/env bash

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/14-kube-apiserver-to-kubelet.md#rbac-for-kubelet-authorization

set -x
set -e
set -u

ssh -T vagrant@192.168.56.11 <<'EOF2'
cat >dns.sh <<'EOF1'
#!/usr/bin/env bash

set -x
set -e
set -u

kubectl apply -f https://raw.githubusercontent.com/mmumshad/kubernetes-the-hard-way/master/deployments/coredns.yaml

# wait for delpoyment
kubectl rollout status -n kube-system deployment/coredns
kubectl get pods -l k8s-app=kube-dns -n kube-system

# verify
cat >pod-busybox.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: busybox
  name: busybox
spec:
  containers:
  - command:
    - sleep
    - "3600"
    image: busybox:1.28
    name: busybox
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
EOF
kubectl apply -f pod-busybox.yaml
kubectl wait --for=condition=Ready pod/busybox
kubectl get pods -l run=busybox
kubectl exec -ti busybox -- nslookup kubernetes
EOF1

bash -x dns.sh
EOF2

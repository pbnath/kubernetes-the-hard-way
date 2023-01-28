#!/usr/bin/env bash

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#bootstrapping-the-kubernetes-control-plane

set -x
set -e
set -u

cat >/tmp/plane.sh <<'EOF'
#!/usr/bin/env bash

set -x
set -e
set -u

wget -q --directory-prefix=/tmp --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/v1.24.3/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.24.3/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.24.3/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.24.3/bin/linux/amd64/kubectl"

{
  chmod +x /tmp/kube-apiserver /tmp/kube-controller-manager /tmp/kube-scheduler /tmp/kubectl
  sudo cp /tmp/kube-apiserver /tmp/kube-controller-manager /tmp/kube-scheduler /tmp/kubectl /usr/local/bin/
}

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-api-server
{
  sudo mkdir -p /var/lib/kubernetes/pki

  # Only copy CA keys as we'll need them again for workers.
  sudo cp ca.crt ca.key /var/lib/kubernetes/pki
  for c in kube-apiserver service-account apiserver-kubelet-client etcd-server kube-scheduler kube-controller-manager
  do
    sudo mv "$c.crt" "$c.key" /var/lib/kubernetes/pki/
  done
  sudo chown root:root /var/lib/kubernetes/pki/*
  sudo chmod 600 /var/lib/kubernetes/pki/*
}

INTERNAL_IP=$(ip addr show enp0s8 | grep "inet " | awk '{print $2}' | cut -d / -f 1)
LOADBALANCER=$(dig +short loadbalancer)

# IP addresses of the two master nodes, where the etcd servers are.
MASTER_1=$(dig +short master-1)
MASTER_2=$(dig +short master-2)

# CIDR ranges used within the cluster
POD_CIDR=10.244.0.0/16
SERVICE_CIDR=10.96.0.0/16

# Create the kube-apiserver.service systemd unit file:
cat <<EOF2 | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=2 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/pki/ca.crt \\
  --enable-admission-plugins=NodeRestriction,ServiceAccount \\
  --enable-bootstrap-token-auth=true \\
  --etcd-cafile=/var/lib/kubernetes/pki/ca.crt \\
  --etcd-certfile=/var/lib/kubernetes/pki/etcd-server.crt \\
  --etcd-keyfile=/var/lib/kubernetes/pki/etcd-server.key \\
  --etcd-servers=https://${MASTER_1}:2379,https://${MASTER_2}:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/pki/ca.crt \\
  --kubelet-client-certificate=/var/lib/kubernetes/pki/apiserver-kubelet-client.crt \\
  --kubelet-client-key=/var/lib/kubernetes/pki/apiserver-kubelet-client.key \\
  --runtime-config=api/all=true \\
  --service-account-key-file=/var/lib/kubernetes/pki/service-account.crt \\
  --service-account-signing-key-file=/var/lib/kubernetes/pki/service-account.key \\
  --service-account-issuer=https://${LOADBALANCER}:6443 \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/pki/kube-apiserver.crt \\
  --tls-private-key-file=/var/lib/kubernetes/pki/kube-apiserver.key \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF2

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-controller-manager
sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/

cat <<EOF2 | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --allocate-node-cidrs=true \\
  --authentication-kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --authorization-kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --bind-address=127.0.0.1 \\
  --client-ca-file=/var/lib/kubernetes/pki/ca.crt \\
  --cluster-cidr=${POD_CIDR} \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/pki/ca.crt \\
  --cluster-signing-key-file=/var/lib/kubernetes/pki/ca.key \\
  --controllers=*,bootstrapsigner,tokencleaner \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --node-cidr-mask-size=24 \\
  --requestheader-client-ca-file=/var/lib/kubernetes/pki/ca.crt \\
  --root-ca-file=/var/lib/kubernetes/pki/ca.crt \\
  --service-account-private-key-file=/var/lib/kubernetes/pki/service-account.key \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF2

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-scheduler
sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/

cat <<EOF2 | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --kubeconfig=/var/lib/kubernetes/kube-scheduler.kubeconfig \\
  --leader-elect=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF2

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#secure-kubeconfigs
sudo chmod 600 /var/lib/kubernetes/*.kubeconfig

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#start-the-controller-services
{
  sudo systemctl daemon-reload
  sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
  sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
}

sleep 30
kubectl get componentstatuses --kubeconfig admin.kubeconfig
EOF

scp /tmp/plane.sh vagrant@192.168.56.11:/tmp/plane.sh

ssh -T vagrant@192.168.56.11 <<'EOF'
    bash -x /tmp/plane.sh

    scp /tmp/plane.sh master-2:/tmp/plane.sh
    ssh -T master-2 <<EOF2
sudo bash /tmp/plane.sh
EOF2
EOF

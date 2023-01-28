#!/usr/bin/env bash

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/07-bootstrapping-etcd.md#bootstrapping-the-etcd-cluster

set -x
set -e
set -u

cat >/tmp/etcd.sh <<'EOF'
#!/usr/bin/env bash

set -x
set -e
set -u

wget -q --show-progress --https-only --timestamping \
  https://github.com/coreos/etcd/releases/download/v3.5.3/etcd-v3.5.3-linux-amd64.tar.gz
{
  tar -xvf etcd-v3.5.3-linux-amd64.tar.gz
  sudo mv etcd-v3.5.3-linux-amd64/etcd* /usr/local/bin/
}

{
  sudo mkdir -p /etc/etcd /var/lib/etcd /var/lib/kubernetes/pki
  sudo cp etcd-server.key etcd-server.crt /etc/etcd/
  sudo cp ca.crt /var/lib/kubernetes/pki/
  sudo chown root:root /etc/etcd/*
  sudo chmod 600 /etc/etcd/*
  sudo chown root:root /var/lib/kubernetes/pki/*
  sudo chmod 600 /var/lib/kubernetes/pki/*
  sudo ln -fs /var/lib/kubernetes/pki/ca.crt /etc/etcd/ca.crt
}

INTERNAL_IP="$(ip addr show enp0s8 | grep "inet " | awk '{print $2}' | cut -d / -f 1)"
MASTER_1="$(dig +short master-1)"
MASTER_2="$(dig +short master-2)"
echo $MASTER_1
echo $MASTER_2

ETCD_NAME="$(hostname -s)"
echo $ETCD_NAME

cat <<EOF1 | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/etcd-server.crt \\
  --key-file=/etc/etcd/etcd-server.key \\
  --peer-cert-file=/etc/etcd/etcd-server.crt \\
  --peer-key-file=/etc/etcd/etcd-server.key \\
  --trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster master-1=https://${MASTER_1}:2380,master-2=https://${MASTER_2}:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF1

sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd

sudo systemctl status etcd
EOF

# https://stackoverflow.com/questions/63433622/is-the-following-output-of-etcdctl-member-list-correct-and-etcd-cluster-is-in
cat >/tmp/etcd_verify.sh <<EOF
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.crt \
  --cert=/etc/etcd/etcd-server.crt \
  --key=/etc/etcd/etcd-server.key

sudo ETCDCTL_API=3 etcdctl endpoint status --write-out=table \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.crt \
  --cert=/etc/etcd/etcd-server.crt \
  --key=/etc/etcd/etcd-server.key
EOF

for script in /tmp/etcd.sh /tmp/etcd_verify.sh; do
    scp $script vagrant@192.168.56.11:$script
done

ssh -T vagrant@192.168.56.11 <<'EOF'
    bash -x /tmp/etcd.sh

    scp /tmp/etcd.sh master-2:/tmp/etcd.sh
    ssh -T master-2 <<EOF2
sudo bash /tmp/etcd.sh
EOF2

    sudo bash /tmp/etcd_verify.sh
    scp /tmp/etcd_verify.sh master-2:/tmp/etcd_verify.sh
    ssh -T master-2 <<EOF2
sudo bash /tmp/etcd_verify.sh
EOF2
EOF

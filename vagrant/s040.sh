#!/usr/bin/env bash

set -x
set -e
set -u

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#certificate-authority
scp certs.sh vagrant@192.168.56.11:/tmp/certs.sh
ssh vagrant@192.168.56.11 sudo bash -x /tmp/certs.sh
cat >/tmp/certs_upload.sh <<'EOF'
#!/usr/bin/env bash

set -x
set -e
set -u

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#distribute-the-certificates
{
    for instance in master-1 master-2; do
        scp ca.crt ca.key kube-apiserver.key kube-apiserver.crt \
            apiserver-kubelet-client.crt apiserver-kubelet-client.key \
            service-account.key service-account.crt \
            etcd-server.key etcd-server.crt \
            kube-controller-manager.key kube-controller-manager.crt \
            kube-scheduler.key kube-scheduler.crt \
            ${instance}:~/
    done

    for instance in worker-1 worker-2; do
        scp ca.crt kube-proxy.crt kube-proxy.key ${instance}:~/
    done
}
EOF

scp /tmp/certs_upload.sh vagrant@192.168.56.11:/tmp/certs_upload.sh

ssh -T vagrant@192.168.56.11 <<EOF
bash -x /tmp/certs_upload.sh
EOF

ssh vagrant@192.168.56.11 bash -x /tmp/certs_upload.sh

scp genkubeconfig.sh vagrant@192.168.56.11:/tmp/genkubeconfig.sh

ssh vagrant@192.168.56.11 bash -x /tmp/genkubeconfig.sh

#!/usr/bin/env bash

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/11-tls-bootstrapping-kubernetes-workers.md#tls-bootstrapping-worker-nodes

set -x
set -e
set -u

scp configure_binaries.sh vagrant@192.168.56.11:/tmp/configure_binaries.sh
ssh -T vagrant@192.168.56.11 <<EOF
    scp /tmp/configure_binaries.sh worker-2:/tmp/configure_binaries.sh
    ssh worker-2 bash -x /tmp/configure_binaries.sh
    kubectl get csr --kubeconfig admin.kubeconfig
    kubectl get nodes --kubeconfig admin.kubeconfig
EOF

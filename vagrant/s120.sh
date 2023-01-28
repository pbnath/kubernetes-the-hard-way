#!/usr/bin/env bash

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/11-tls-bootstrapping-kubernetes-workers.md#tls-bootstrapping-worker-nodes

set -x
set -e
set -u

scp tls_bootstrap.sh vagrant@192.168.56.11:/tmp/tls_bootstrap.sh
ssh vagrant@192.168.56.11 bash -x /tmp/tls_bootstrap.sh

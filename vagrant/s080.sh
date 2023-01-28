#!/usr/bin/env bash

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#the-kubernetes-frontend-load-balancer

set -x
set -e
set -u

scp loadbalancer.sh vagrant@192.168.56.30:/tmp/loadbalancer.sh
ssh -T vagrant@192.168.56.30 <<'EOF'
    bash -x /tmp/loadbalancer.sh
EOF

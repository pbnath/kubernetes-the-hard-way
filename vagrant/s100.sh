#!/usr/bin/env bash

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/09-install-cri-workers.md#installing-cri-on-the-kubernetes-worker-nodes

set -x
set -e
set -u

scp cri.sh vagrant@192.168.56.30:/tmp/cri.sh
ssh vagrant@192.168.56.30 bash -x /tmp/cri.sh

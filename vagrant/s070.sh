#!/usr/bin/env bash

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#bootstrapping-the-kubernetes-control-plane

set -x
set -e
set -u

scp control_plane.sh vagrant@192.168.56.11:/tmp/control_plane.sh
ssh -T vagrant@192.168.56.11 <<'EOF'
    bash -x /tmp/control_plane.sh

    scp /tmp/control_plane.sh master-2:/tmp/control_plane.sh
    ssh -T master-2 <<EOF2
sudo bash /tmp/control_plane.sh
EOF2
EOF

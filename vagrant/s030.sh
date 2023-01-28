#!/usr/bin/env bash

# https://youtu.be/pcgpRlYpEgI?list=PL2We04F3Y_41jYdadX55fdJplDvgNGENo&t=123

set -x
set -e
set -u

cat >/tmp/kubectl_install.sh <<'EOF'
wget -q --directory-prefix=cache --show-progress --https-only --timestamping \
    https://storage.googleapis.com/kubernetes-release/release/v1.24.3/bin/linux/amd64/kubectl
chmod +x kubectl
sudo cp kubectl /usr/local/bin/
kubectl version -oyaml --client|awk '/gitVersion/{print $2;}'
EOF

chmod +x /tmp/kubectl_install.sh
scp /tmp/kubectl_install.sh vagrant@192.168.56.11:/tmp/kubectl_install.sh
ssh vagrant@192.168.56.11 sudo bash -x /tmp/kubectl_install.sh

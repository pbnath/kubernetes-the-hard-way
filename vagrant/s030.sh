#!/usr/bin/env bash

# https://youtu.be/pcgpRlYpEgI?list=PL2We04F3Y_41jYdadX55fdJplDvgNGENo&t=123

set -x
set -e
set -u

cat >/tmp/kubectl_install.sh <<'EOF'
curl -sSLo /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
install --mode 0755 --group root --owner root /tmp/kubectl /usr/local/bin/kubectl
rm -f /tmp/kubectl
kubectl version --output=yaml
kubectl version -oyaml --client|awk '/gitVersion/{print $2;}'
EOF

chmod +x /tmp/kubectl_install.sh
scp /tmp/kubectl_install.sh vagrant@192.168.56.11:/tmp/kubectl_install.sh
ssh vagrant@192.168.56.11 sudo bash -x /tmp/kubectl_install.sh

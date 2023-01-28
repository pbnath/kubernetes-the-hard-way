#!/usr/bin/env bash

set -x
set -e
set -u

vagrant plugin install vagrant-scp
vagrant plugin list
vagrant status

cat >enableroot.sh <<EOF
#!/bin/bash
sudo mkdir -p /root/.ssh/
cat /tmp/id_ed25519.pub |sudo tee -a /root/.ssh/authorized_keys
EOF
chmod +x enableroot.sh

declare -a hosts=('master-1')
declare -a hosts=('master-1' 'master-2' 'loadbalancer' 'worker-1' 'worker-2')
for host in "${hosts[@]}"; do
    vagrant scp ~/.ssh/id_ed25519.pub "$host:/tmp/id_ed25519.pub"
    vagrant scp enableroot.sh "$host:/tmp/enableroot.sh"
    vagrant ssh "$host" --command 'sudo /tmp/enableroot.sh'
done

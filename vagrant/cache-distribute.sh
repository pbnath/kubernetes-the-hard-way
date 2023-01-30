#!/usr/bin/env bash

exec &> >(tee -a log.txt)

set -x
set -e
set -u

vagrant scp /Users/mtm/pdev/taylormonacelli/kubernetes-the-hard-way/vagrant/cache/ master-1:

ssh -T vagrant@192.168.56.11<<'EOF'
    for host in master-1 master-2 loadbalancer worker-1 worker-2; do
        rsync -va cache/ $host: &
    done
    wait
EOF

#!/usr/bin/env bash

exec &> >(tee -a log.txt)


set -x
set -e
set -u

ssh -T vagrant@192.168.56.11<<'EOF'
rm -rf quick-steps
EOF

rm -rf /Users/mtm/pdev/taylormonacelli/kubernetes-the-hard-way/quick-steps/
python3 /Users/mtm/pdev/taylormonacelli/kubernetes-the-hard-way/tools/lab-script-generator.py --path /Users/mtm/pdev/taylormonacelli/kubernetes-the-hard-way/docs
ls -1d /Users/mtm/pdev/taylormonacelli/kubernetes-the-hard-way/quick-steps/* | sort -n

vagrant scp /Users/mtm/pdev/taylormonacelli/kubernetes-the-hard-way/quick-steps/ master-1:

ssh -T vagrant@192.168.56.11<<'EOF'
    for host in master-1 master-2 loadbalancer worker-1 worker-2; do
        rsync -va quick-steps $host: &
        # rsync -va cache/ $host: &
    done
    wait
EOF

scp stuff3.sh vagrant@192.168.56.11:
ssh -T vagrant@192.168.56.11 <<'EOF'
    bash -x stuff3.sh
EOF

#!/usr/bin/env bash

set -x
set -e
set -u

rm -rf /Users/mtm/pdev/taylormonacelli/kubernetes-the-hard-way/quick-steps/
python3 /Users/mtm/pdev/taylormonacelli/kubernetes-the-hard-way/tools/lab-script-generator.py --path /Users/mtm/pdev/taylormonacelli/kubernetes-the-hard-way/docs
ls -1d /Users/mtm/pdev/taylormonacelli/kubernetes-the-hard-way/quick-steps/* | sort -n

vagrant scp /Users/mtm/pdev/taylormonacelli/kubernetes-the-hard-way/vagrant/cache/ master-1:
vagrant scp /Users/mtm/pdev/taylormonacelli/kubernetes-the-hard-way/quick-steps/ master-1:

scp stuff3.sh vagrant@192.168.56.11:
ssh -T vagrant@192.168.56.11 <<'EOF'
    bash -x stuff3.sh
EOF

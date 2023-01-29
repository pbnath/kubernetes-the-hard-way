#!/usr/bin/env bash

set -x
set -e
set -u

for host in master-1 master-2 loadbalancer worker-1 worker-2; do
    rsync -a quick-steps/ $host: &
    rsync -a cache/ $host: &
done
wait

set +e

# bash -x 03a-master-1.sh
bash -x 03b-master-1.sh
bash -x 04a-master-1.sh </dev/null
bash -x 05a-master-1.sh </dev/null
bash -x 06a-master-1.sh
bash -x 07a-master-1-master2.sh
ssh master-2 bash -x 07a-master-1-master2.sh
bash -x 08a-master-1-master2.sh </dev/null
ssh master-2 bash -x 08a-master-1-master2.sh
ssh loadbalancer bash -x 08b-loadbalancer.sh
ssh worker-1 bash -x 09a-worker-1-worker-2.sh
ssh worker-2 bash -x 09a-worker-1-worker-2.sh
bash -x 10a-master-1.sh
ssh -T worker-1 <<EOF
    bash -x 10b-worker-1.sh </dev/null
EOF
bash -x 10c-master-1.sh
bash -x 11a-master-1.sh
ssh -T worker-2 <<EOF
    bash -x 11b-worker-2.sh </dev/null
EOF
bash -x 11c-master-1.sh
bash -x 12a-master-1.sh
bash -x 13a-master-1.sh
bash -x 14a-master-1.sh
bash -x 15a-master-1.sh
bash -x 16a-master-1.sh

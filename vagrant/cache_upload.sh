#!/usr/bin/env bash

set -x
set -e
set -u

unset hosts
declare -a hosts
hosts+=('master-1')
hosts+=('master-2')
hosts+=('loadbalancer')
hosts+=('worker-1')
hosts+=('worker-2')

for host in "${hosts[@]}"; do
    vagrant scp cache "$host:"
    vagrant ssh "$host" --command 'for file in cache/*; do cp -r $file ~; done'
done

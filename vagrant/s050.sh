#!/usr/bin/env bash

set -x
set -e
set -u

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/06-data-encryption-keys.md#the-encryption-key
scp encrypt.sh vagrant@192.168.56.11:/tmp/encrypt.sh
ssh vagrant@192.168.56.11 bash -x /tmp/encrypt.sh

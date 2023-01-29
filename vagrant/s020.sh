#!/usr/bin/env bash

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/02-compute-resources.md#provisioning-compute-resources

exec &> >(tee -a log.txt)

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

# host2 is hosts minus master's hostname
unset host2
declare -a hosts2
hosts2=("${hosts[@]}")
unset 'hosts2[0]'
echo "${hosts2[@]}"

unset hostips
declare -a hostips
hostips+=('192.168.56.11')
hostips+=('192.168.56.12')
hostips+=('192.168.56.21')
hostips+=('192.168.56.22')
hostips+=('192.168.56.30')

# hostips2 is hostips minus master's ip
unset hostips2
declare -a hostips2
hostips2=("${hostips[@]}")
unset 'hostips2[0]'
echo "${hostips2[@]}"

for ip in "${hostips[@]}"; do
    ssh-keygen -R "$ip"
done

for host in "${hosts[@]}"; do
    vagrant scp ~/.ssh/id_ed25519.pub "$host:/tmp/id_ed25519.pub"
done

cat >/tmp/ssh_allow.sh <<'EOF'
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
cat /tmp/id_ed25519.pub >>/home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/*
EOF
chmod +x /tmp/ssh_allow.sh

for host in "${hosts[@]}"; do
    vagrant scp /tmp/ssh_allow.sh "$host:/tmp/ssh_allow.sh"
    vagrant ssh "$host" --command /tmp/ssh_allow.sh
done

# Create key on master-1 and copy it to the other hosts:
ssh -T vagrant@192.168.56.11 <<'EOF'
    mkdir -p .ssh
    echo y | ssh-keygen -t rsa -C $(id -nu)@$(hostname) -f ~/.ssh/id_rsa -N ''
    cat ~/.ssh/id_rsa.pub >>~/.ssh/authorized_keys
EOF

scp vagrant@192.168.56.11:.ssh/id_rsa.pub /tmp

# remove master ip since its the key we'ere copying to the others
unset 'hostips[0]'

for ip in "${hostips[@]}"; do
    scp /tmp/id_rsa.pub "vagrant@$ip:/tmp/id_rsa.pub"
    ssh -T "vagrant@$ip" <<'EOF'
    mkdir -p /home/vagrant/.ssh
    cat /tmp/id_rsa.pub >>/home/vagrant/.ssh/authorized_keys
EOF
done

cat >/tmp/stuff.sh <<EOF
    for hostname in ${hosts[@]}; do
        ssh-keyscan -t rsa \$hostname >>~/.ssh/known_hosts
    done
    for ip in ${hostips[@]}; do
        ssh-keyscan -t rsa \$ip >>~/.ssh/known_hosts
    done
EOF
scp /tmp/stuff.sh vagrant@192.168.56.11:/tmp/stuff.sh
ssh vagrant@192.168.56.11 bash -x /tmp/stuff.sh

scp /tmp/stuff.sh vagrant@192.168.56.11:/tmp/stuff.sh
ssh vagrant@192.168.56.11 bash -x /tmp/stuff.sh

cat >/tmp/stuff2.sh <<EOF
    for hostname in ${hosts2[@]}; do
        ssh vagrant@\$hostname ls
    done
EOF
chmod +x /tmp/stuff2.sh

vagrant scp /tmp/stuff2.sh master-1:/tmp/stuff2.sh
vagrant ssh master-1 --command 'bash -x /tmp/stuff2.sh'

vagrant scp /Users/mtm/pdev/taylormonacelli/kubernetes-the-hard-way/vagrant/cache/ master-1:

ssh -T vagrant@192.168.56.11<<'EOF'
    for host in master-1 master-2 loadbalancer worker-1 worker-2; do
        rsync -va cache/ $host: &
    done
    wait
EOF

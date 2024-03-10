#!/bin/bash

# Enable password auth in sshd so we can use ssh-copy-id
sed -i --regexp-extended 's/#?PasswordAuthentication (yes|no)/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i --regexp-extended 's/#?Include \/etc\/ssh\/sshd_config.d\/\*.conf/#Include \/etc\/ssh\/sshd_config.d\/\*.conf/' /etc/ssh/sshd_config
systemctl restart sshd

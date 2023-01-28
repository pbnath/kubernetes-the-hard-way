#!/usr/bin/env bash

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#certificate-authority

set -x
set -e
set -u

MASTER_1="$(dig +short master-1)"
MASTER_2="$(dig +short master-2)"
LOADBALANCER="$(dig +short loadbalancer)"

SERVICE_CIDR=10.96.0.0/24
API_SERVICE="$(echo $SERVICE_CIDR | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s.1", $1, $2, $3) }')"

echo "$MASTER_1"
echo "$MASTER_2"
echo "$LOADBALANCER"
echo "$SERVICE_CIDR"
echo "$API_SERVICE"

{
    # Create private key for CA
    openssl genrsa -out ca.key 2048

    # Comment line starting with RANDFILE in /etc/ssl/openssl.cnf definition to avoid permission issues
    sudo sed -i '0,/RANDFILE/{s/RANDFILE/\#&/}' /etc/ssl/openssl.cnf

    # Create CSR using the private key
    openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA/O=Kubernetes" -out ca.csr

    # Self sign the csr using its own private key
    openssl x509 -req -in ca.csr -signkey ca.key -CAcreateserial -out ca.crt -days 1000
}

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#client-and-server-certificates
{
    # Generate private key for admin user
    openssl genrsa -out admin.key 2048

    # Generate CSR for admin user. Note the OU.
    openssl req -new -key admin.key -subj "/CN=admin/O=system:masters" -out admin.csr

    # Sign certificate for admin user using CA servers private key
    openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out admin.crt -days 1000
}

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-kubelet-client-certificates
{
    openssl genrsa -out kube-controller-manager.key 2048

    openssl req -new -key kube-controller-manager.key \
        -subj "/CN=system:kube-controller-manager/O=system:kube-controller-manager" -out kube-controller-manager.csr

    openssl x509 -req -in kube-controller-manager.csr \
        -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-controller-manager.crt -days 1000
}

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-kube-proxy-client-certificate
{
    openssl genrsa -out kube-proxy.key 2048

    openssl req -new -key kube-proxy.key \
        -subj "/CN=system:kube-proxy/O=system:node-proxier" -out kube-proxy.csr

    openssl x509 -req -in kube-proxy.csr \
        -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-proxy.crt -days 1000
}

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-scheduler-client-certificate
{
    openssl genrsa -out kube-scheduler.key 2048

    openssl req -new -key kube-scheduler.key \
        -subj "/CN=system:kube-scheduler/O=system:kube-scheduler" -out kube-scheduler.csr

    openssl x509 -req -in kube-scheduler.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-scheduler.crt -days 1000
}

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-kubernetes-api-server-certificate
cat >openssl.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = critical, CA:FALSE
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
IP.1 = ${API_SERVICE}
IP.2 = ${MASTER_1}
IP.3 = ${MASTER_2}
IP.4 = ${LOADBALANCER}
IP.5 = 127.0.0.1
EOF

{
    openssl genrsa -out kube-apiserver.key 2048

    openssl req -new -key kube-apiserver.key \
        -subj "/CN=kube-apiserver/O=Kubernetes" -out kube-apiserver.csr -config openssl.cnf

    openssl x509 -req -in kube-apiserver.csr \
        -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-apiserver.crt -extensions v3_req -extfile openssl.cnf -days 1000
}

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-kubelet-client-certificate
cat >openssl-kubelet.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = critical, CA:FALSE
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF

{
    openssl genrsa -out apiserver-kubelet-client.key 2048

    openssl req -new -key apiserver-kubelet-client.key \
        -subj "/CN=kube-apiserver-kubelet-client/O=system:masters" -out apiserver-kubelet-client.csr -config openssl-kubelet.cnf

    openssl x509 -req -in apiserver-kubelet-client.csr \
        -CA ca.crt -CAkey ca.key -CAcreateserial -out apiserver-kubelet-client.crt -extensions v3_req -extfile openssl-kubelet.cnf -days 1000
}

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-etcd-server-certificate
cat >openssl-etcd.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = ${MASTER_1}
IP.2 = ${MASTER_2}
IP.3 = 127.0.0.1
EOF

{
    openssl genrsa -out etcd-server.key 2048

    openssl req -new -key etcd-server.key \
        -subj "/CN=etcd-server/O=Kubernetes" -out etcd-server.csr -config openssl-etcd.cnf

    openssl x509 -req -in etcd-server.csr \
        -CA ca.crt -CAkey ca.key -CAcreateserial -out etcd-server.crt -extensions v3_req -extfile openssl-etcd.cnf -days 1000
}

# https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-service-account-key-pair
{
    openssl genrsa -out service-account.key 2048

    openssl req -new -key service-account.key \
        -subj "/CN=service-accounts/O=Kubernetes" -out service-account.csr

    openssl x509 -req -in service-account.csr \
        -CA ca.crt -CAkey ca.key -CAcreateserial -out service-account.crt -days 1000
}

# FIXME: WORKAROUND
echo FIXME: WORKAROUND
sudo chmod a+rwx ./*

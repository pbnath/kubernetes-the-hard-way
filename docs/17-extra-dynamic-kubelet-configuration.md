# Dynamic Kubelet Configuration

From master-1, get the kubelet configuration of node worker-1
```
NODE_NAME="worker-1"
curl -sSL "https://localhost:6443/api/v1/nodes/${NODE_NAME}/proxy/configz" -k --cert admin.crt --key admin.key \
  | jq '.kubeletconfig|.kind="KubeletConfiguration"|.apiVersion="kubelet.config.k8s.io/v1beta1"' \
  > kubelet_configz_${NODE_NAME}
```

Create the configmap from the kubelet configuration, and get the configmap name after creation. You will need this name in next step.
```
kubectl -n kube-system create configmap nodes-config --from-file=kubelet=kubelet_configz_${NODE_NAME} \
  --append-hash -o yaml | grep "  name: " 

```

Edit `worker-1` node to use the dynamically created configuration
```
master-1# kubectl edit node worker-1
```

Add the following YAML bit under `spec`:
```
configSource:
    configMap:
        name: CONFIG_MAP_NAME # replace CONFIG_MAP_NAME with the name of the ConfigMap
        namespace: kube-system
        kubeletConfigKey: kubelet
```

Configure Kubelet Service

Next steps need to be performed on worker-1 node.

Login into worker-1 and create the `kubelet.service` systemd unit file:

```
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --bootstrap-kubeconfig="/var/lib/kubelet/bootstrap-kubeconfig" \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --dynamic-config-dir=/var/lib/kubelet/dynamic-config \\
  --cert-dir= /var/lib/kubelet/ \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Finally, refresh the daemon service and restart kubelet service. You can see it switching to dynamic config on the logs.
```
sudo systemctl daemon-reload
sudo systemctl restart kubelet
sleep 60 # (we give it a minute to start)
sudo systemctl status kubelet
```

Reference: https://kubernetes.io/docs/tasks/administer-cluster/reconfigure-kubelet/

# Dynamic Kubelet Configuration


```bash
sudo apt install -y jq
NODE_NAME="worker-1"
curl -sSL "https://localhost:6443/api/v1/nodes/${NODE_NAME}/proxy/configz" -k --cert admin.crt --key admin.key | jq '.kubeletconfig|.kind="KubeletConfiguration"|.apiVersion="kubelet.config.k8s.io/v1beta1"' > kubelet_configz_${NODE_NAME}
```

Create configMap for node config and take note of created configMap name
```bash
kubectl -n kube-system create configmap ${NODE_NAME}-config --from-file=kubelet=kubelet_configz_${NODE_NAME} --append-hash -o yaml
```

Edit node to use the dynamically created configuration. Let's say name of previously created configmap was `CONFIG_MAP_NAME`
```
kubectl edit ${NODE_NAME}
```

add following under the `spec` section (remove existing spec fields, if any)
```
configSource:
    configMap:
        name: CONFIG_MAP_NAME # replace CONFIG_MAP_NAME with the name of the ConfigMap
        namespace: kube-system
        kubeletConfigKey: kubelet

```

Configure/update Kubelet Service for NODE_NAME (worker-1)

```
sudo mkdir -p /var/lib/kubelet/dynamic-config
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --dynamic-config-dir=/var/lib/kubelet/dynamic-config \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --tls-cert-file=/var/lib/kubelet/worker-1.crt \\
  --tls-private-key-file=/var/lib/kubelet/worker-1.key \\
  --network-plugin=cni \\
  --register-node=true \\
  --fail-swap-on=false \\
  --v=2
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

Next, try editing the configMap and update some of the configuration values. Notice that kubelet restarts by itself and reloads new configs  
Resource: https://kubernetes.io/docs/tasks/administer-cluster/reconfigure-kubelet/

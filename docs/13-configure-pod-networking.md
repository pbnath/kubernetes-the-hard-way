# Provisioning Pod Network

Container Network Interface (CNI) is a standard interface for managing IP networks between containers across many nodes.

We chose to use CNI - [weave](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/) as our networking option.

# Prerequisite on Worker Nodes

Install cni support binaries on worker nodes for weave-net. 

[//]: # (host:worker-1-worker-2)

On `worker-1` & `worker-2`

```bash
{
  sudo mkdir -p /opt/cni/bin
  sudo wget https://github.com/containernetworking/plugins/releases/download/v0.9.0/cni-plugins-linux-amd64-v0.9.0.tgz -P /opt/cni/bin/
  sudo tar -xzvf /opt/cni/bin/cni-plugins-linux-amd64-v0.9.0.tgz -C /opt/cni/bin/
}
```

### Deploy Weave Network

Deploy weave network. Run only once on the `master-1` node. You will see a warning, but this is OK.

[//]: # (host:master-1)

On `master-1`

```bash
kubectl apply -f "https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s-1.11.yaml"
```

Weave uses POD CIDR of `10.32.0.0/12` by default.

## Verification

[//]: # (command:kubectl rollout status daemonset weave-net -n kube-system --timeout=90s)

List the registered Kubernetes nodes from the master node:

```bash
kubectl get pods -n kube-system
```

> output

```
NAME              READY   STATUS    RESTARTS   AGE
weave-net-58j2j   2/2     Running   0          89s
weave-net-rr5dk   2/2     Running   0          89s
```

Once the Weave pods are fully running which might take up to 60 seconds, the nodes should be ready

```bash
kubectl get nodes
```

> Output

```
NAME       STATUS   ROLES    AGE     VERSION
worker-1   Ready    <none>   4m11s   v1.24.3
worker-2   Ready    <none>   2m49s   v1.24.3
```

Reference: https://kubernetes.io/docs/tasks/administer-cluster/network-policy-provider/weave-network-policy/#install-the-weave-net-addon

Prev: [Configuring Kubectl](12-configuring-kubectl.md)</br>
Next: [Kube API Server to Kubelet Connectivity](14-kube-apiserver-to-kubelet.md)

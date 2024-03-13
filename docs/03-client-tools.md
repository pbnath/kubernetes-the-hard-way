# Installing the Client Tools

First identify a system from where you will perform administrative tasks, such as creating certificates, `kubeconfig` files and distributing them to the different VMs.

If you are on a Linux laptop, then your laptop could be this system. In my case I chose the `controlplane01` node to perform administrative tasks. Whichever system you chose make sure that system is able to access all the provisioned VMs through SSH to copy files over.

## Access all VMs

Here we create an SSH key pair for the `vagrant` user who we are logged in as. We will copy the public key of this pair to the other control and both workers to permit us to use password-less SSH (and SCP) go get from `controlplane01` to these other nodes in the context of the `vagrant` user which exists on all nodes.

Generate SSH key pair on `controlplane01` node:

[//]: # (host:controlplane01)

```bash
ssh-keygen
```

Leave all settings to default by pressing `ENTER` at any prompt.

Add this key to the local `authorized_keys` (`controlplane01`) as in some commands we `scp` to ourself.

```bash
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

Copy the key to the other hosts. You will be asked to enter a password for each of the `ssh-copy-id` commands. The password is:
* VirtualBox - `vagrant`
* Apple Silicon: `ubuntu`

The option `-o StrictHostKeyChecking=no` tells it not to ask if you want to connect to a previously unknown host. Not best practice in the real world, but speeds things up here.

`$(id -u)` selects the appropriate user name to connect to the remote VMs. On VirtualBox this evaluates to `vagrant`; on Apple Silicon it is `ubuntu`.

```bash
ssh-copy-id -o StrictHostKeyChecking=no $(id -u)@controlplane02
ssh-copy-id -o StrictHostKeyChecking=no $(id -u)@loadbalancer
ssh-copy-id -o StrictHostKeyChecking=no $(id -u)@node01
ssh-copy-id -o StrictHostKeyChecking=no $(id -u)@node02
```



For each host, the output should be similar to this. If it is not, then you may have entered an incorrect password. Retry the step.

```
Number of key(s) added: 1
```

Verify connection

```
ssh controlplane01
exit

ssh controlplane02
exit

ssh node01
exit

ssh node02
exit
```


## Install kubectl

The [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl) command line utility is used to interact with the Kubernetes API Server. Download and install `kubectl` from the official release binaries:

Reference: [https://kubernetes.io/docs/tasks/tools/install-kubectl/](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

We will be using `kubectl` early on to generate `kubeconfig` files for the controlplane components.

### Linux

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### Verification

Verify `kubectl` is installed:

```
kubectl version -o yaml
```

output will be similar to this, although versions may be newer:

```
kubectl version -o yaml
clientVersion:
  buildDate: "2023-11-15T16:58:22Z"
  compiler: gc
  gitCommit: bae2c62678db2b5053817bc97181fcc2e8388103
  gitTreeState: clean
  gitVersion: v1.28.4
  goVersion: go1.20.11
  major: "1"
  minor: "28"
  platform: linux/amd64
kustomizeVersion: v5.0.4-0.20230601165947-6ce0bf390ce3

The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

Don't worry about the error at the end as it is expected. We have not set anything up yet!

Next: [Certificate Authority](04-certificate-authority.md)<br>
Prev: Compute Resources ([VirtualBox](../VirtualBox/docs/02-compute-resources.md)), ([Apple Silicon](../apple-silicon/docs/02-compute-resources.md))
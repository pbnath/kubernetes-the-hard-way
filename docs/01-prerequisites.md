# Prerequisites

## VM Hardware Requirements

8 GB of RAM (Preferably 16 GB)
50 GB Disk space

## Virtual Box

Download and Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads) on any one of the supported platforms:

 - Windows hosts
 - OS X hosts
 - Linux distributions
 - Solaris hosts

## Vagrant

Once VirtualBox is installed you may chose to deploy virtual machines manually on it.
Vagrant provides an easier way to deploy multiple virtual machines on VirtualBox more consistenlty.

Download and Install [Vagrant](https://www.vagrantup.com/) on your platform.

- Windows
- Debian
- Centos
- Linux
- macOS

## If you use Windows 10 and Hyper-V
For the image used in the "Getting Started" guide (hashicorp/bionic64), Vagrant tries to use SMBv1 for shared folders.
Enable SMBv1:
```
Enable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol-Client" -All
```

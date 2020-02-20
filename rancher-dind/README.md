# rancher-dind

> Useful for testing rancher deployments, upgrades and features

This lab provides multiple [rancher](https://rancher.com/) scenarios. These scenarios build [rke](https://rancher.com/docs/rke/latest/en/) or [k3s](https://k3s.io/) clusters. It also has scenarios for [rio](https://rio.io/)

## Requirements

- docker --- *for local multi node clusters*
- keygen --- almost all OSes have it now and its only used during `init` to generate an rsa key used for `ssh`
- Should work with:  `8 Cores` | `16G RAM` | `10G Storage`

## How to use

> There is a [./run.ps1](./run.ps1) script that usually just wraps `docker-compose`, if you are on **linux** `cat` the file and run commands directly or install [powershell core](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7#ubuntu-1804)

- Git clone this repo

- Start the cluster of rancher and nodes --- *do not use a passphrase, just press enter*
  ```powershell
  ./run.ps1 init
  ```
- Enter the `provisioner` named `core`
  ```powershell
  ./run.ps1 core
  ```
- From `core`, deploy an `rke` cluster using the [provision/cli-basic/cluster.yml](./provision/cli-basic/cluster.yml)
  > **Important** In case you are **not** using **wsl 2**, read notes further down on this README 
  ```bash
  cd provision/cli-ha
  # vi cluster.yml # if needed
  rke up
  ```
- You should have a cluster come up and you can verify it did with
  ```bash
  kubectl get po -A
  ```
- To reset you can use (equivalent to a super quick vm wipe)
  ```powershell
  ./run.ps1 reset
  ```
- By default `node-1` port `80` and `443` are mapped on your docker host and as long as `node-1` is a worker in the cluster, you can access **http://localhost** or an ingress with **http://someapp.lvh.me**

- To access rancher open you browser at [https://localhost:8443](https://localhost:8443), when asked for a **URL** for rancher server, use **https://rancher** (**nodes** can resolve this url). You can **import** the previously created cluster in order to start administrating it via rancher (run the `curl` command via `core`)
  > **Cloud Provider** If you want to test a cloud provider you can expose rancher via [ngrok](https://ngrok.com/) so the cloud nodes can reach it (it only works for some time), but for cloud providers you can also just deploy rancher up there
  
Generally speaking you can enter any directory under **provision** and run `rke`, `terraform` or `kubectl`

In `core` **KUBECONFIG** env defaults to `./kube_config_cluster.yml`


---


### Highlights
- It leverages `docker-compose` for portability --- *Should work with Windows/Mac/Linux as long as you have docker installed*
- It uses `docker:dind` for the **nodes** and enables ssh to **simulate VM usage** --- *Instead of using VMs via vagrant or a specific hypervisor*
- It deploys **rancher** server
- It deploys a "vm" named `core` that can be used to run `rke` or `terraform` commands to interact with **rancher** and **nodes**

### Notes
- If you are behind a corporate proxy. Add your corp `ca.pem` into [corp](./corp) directory, the ca will be used during `init` on **nodes** and **rancher**
- If you are **not** using **wsl 2** on **windows**, then make sure to add the following to `cluster.yml` for `rke` and equivalent for `terraform`
  ```yaml
  services:
    kubeproxy:
      extra_args:
        # https://github.com/kubernetes/kubernetes/issues/25543
        # https://github.com/kubernetes-retired/kubeadm-dind-cluster/issues/50
        # conntrack-max: 0
        conntrack-max-per-core: 0
  ```
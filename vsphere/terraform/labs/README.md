# Labs

## 00-setup

It will generate an `ssh key` and distribute `authorized_keys` for user `test`. It will also setup 3 nodes as routers for each az subnet. These will act as the entry points to execute commands

## 00-setup-opnsense

> TODO: The setup is a bit manual, automate and add here

It assumes only 1 node is expose as a workstation into the subnets and the routing/connectivity is managed  by an opnsense

## 01-ks8-az

|network|server|description|
|-|-|-|
|az1|10.211.0.10|Cluster 1 `c01.k`|
|az2|10.212.0.10|Cluster 2 `c02.k`|
|az9|10.219.0.10|Rancher and central DNS & LB|

- Use 10.219.0.40 as your workstation, by accessing it via https://$EXTSUBNET.40

# Files

|name|description|
|-|-|
|config/domain|domain you own to use for coredns and wildcard cert|
|config/subnet|a subnet prefix x.x.x that is reachable from your workstation, used as $EXTSUBNET in scripts|
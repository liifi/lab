# Labs

## 01-ks8-az

|network|server|description|
|-|-|-|
|az1|10.111.0.10|Cluster 1 `c01.k`|
|az2|10.112.0.10|Cluster 2 `c02.k`|
|az9|10.119.0.10|Rancher and central DNS & LB|

- Add az9 mgmnt server ip (`10.119.0.10`) as DNS server the az9 network adapter on Windows. Leave your primary adapter's DNS server untouched

# Files

|name|description|
|-|-|
|config/domain|domain you own to use for coredns and wildcard cert|
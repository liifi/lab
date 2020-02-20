# cli-ha-rancher

## Nodes

- node-4
- node-5
- node-6

# Usage

```bash
rke up
./install-rancher.sh
```

# Details

- This lab example will setup rancher in HA mode using helm and self signed certificate.
- It will not use an LB since its a quick lab
- It will send all traffic to **node-4**
- To access from your workstation (host of these labs), update your hosts files to have ```127.0.0.1 node-4```
- After deploying the cluster and rancher use the following to tail for logs
  ```
  # kubectl get po -w
  kubectl logs -f -lapp=rancher
  ```
- After rancher comes up and waits for server url, open https://node-4:4443 on your browser
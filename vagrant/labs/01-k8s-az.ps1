#!/usr/bin/env pwsh

##########################

. "$PSScriptRoot/_utils.ps1"

##########################

# Define the management ip (central dns and rancher)
$MGMT_IP = "10.119.0.10"
$DOMAIN = Get-Content -Raw $PSScriptRoot/config/domain
$USER = "vagrant"

##########################

# CoreDNS config file for central DNS
[System.IO.File]::WriteAllLines("$tmp/Corefile", @"
.:53 {
    forward . 8.8.8.8 8.8.4.4
    log
    errors
}

c01.k:53 {
    errors
    cache 30
    forward . 10.111.0.200
    reload
}

c02.k:53 {
    errors
    cache 30
    forward . 10.112.0.200
    reload
}

${DOMAIN}:53 {
    file /conf/coredns.${DOMAIN}.db
    log
    errors
}

100.0.10.in-addr.arpa {
    file /conf/coredns.arpa.db
    log
    errors
}
"@
)

####

# SOA name email serial refresh retry soa-expire ttl
[System.IO.File]::WriteAllLines("$tmp/coredns.${DOMAIN}.db", @"
@                       IN  SOA   dns.${DOMAIN}. admin.${DOMAIN}. 2015082541 7200 3600 1209600 3600
dns           IN  A     $MGMT_IP
rancher       IN  A     $MGMT_IP
netc01        IN  A     10.111.0.10
netc02        IN  A     10.112.0.10
testing       IN  A     127.0.0.2
example       IN  A     127.0.0.1
example2      IN  CNAME example
example3      IN  CNAME example
example4      IN  CNAME example
"@
)

[System.IO.File]::WriteAllLines("$tmp/coredns.arpa.db", @"
@ IN SOA dns.${DOMAIN}. admin.${DOMAIN}. (
3 ; Serial
604800 ; Refresh
86400 ; Retry
2419200 ; Expire
604800 ) ; Negative Cache TTL
;

; name servers - NS records

@ IN NS dns.${DOMAIN}.

; PTR records

10 IN PTR dns.${DOMAIN}.
"@
)



####

$setup_coredns= @"
echo -e '\U0001F4A1' `$HOSTNAME: setup coredns...
docker run --name coredns -d --restart=unless-stopped -v /home/${USER}:/conf -p ${MGMT_IP}:53:53/tcp -p${MGMT_IP}:53:53/udp coredns/coredns -conf /conf/Corefile
docker restart coredns
sleep 1
"@

####

$setup_k3s = @"
echo -e '\U0001F4A1' `$HOSTNAME: setup k3s...
export INSTALL_K3S_VERSION=v1.22.13+k3s1
# export K3S_KUBECONFIG_MODE=644
curl -sfL https://get.k3s.io | sh -
mkdir -p /home/${USER}/.kube && chown ${USER}:${USER} /home/${USER}/.kube
ln -s /etc/rancher/k3s/k3s.yaml /home/${USER}/.kube/config
sudo chown ${USER}:${USER} /etc/rancher/k3s/k3s.yaml
kubectl cluster-info
RESULT=`$?
if [ `$RESULT -eq 0 ]; then
  echo -e '\U0001F4A1' `$HOSTNAME: k3s is installed
else
  echo -e '\U0001F4A1' `$HOSTNAME: booting k3s...
  sleep 10
fi
"@

####

$setup_rke2 = @"
echo -e '\U0001F4A1' `$HOSTNAME: setup rke2...
# TODO Create cluster in rancher and run command here
mkdir -p /home/${USER}/.kube && chown ${USER}:${USER} /home/${USER}/.kube
ln -s /etc/rancher/rke2/rke2.yaml /home/${USER}/.kube/config
sudo chown ${USER}:${USER} /etc/rancher/rke2/rke2.yaml

sudo bash -c 'echo "sudo /var/lib/rancher/rke2/bin/crictl --config /var/lib/rancher/rke2/agent/etc/crictl.yaml \"\$@\"" > /usr/bin/crictl'
sudo bash -c 'echo "sudo /var/lib/rancher/rke2/bin/ctr --address /run/k3s/containerd/containerd.sock --namespace k8s.io container \"\$@\"" > /usr/bin/ctr'
sudo chmod +x /usr/bin/crictl /usr/bin/ctr
"@


###

$setup_sample = @"
echo -e '\U0001F4A1' `$HOSTNAME: setup sample...
cat > sample.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: default
spec:
  selector:
    matchLabels:
      k8s-app: web # Used in hubble-ui
  replicas: 2
  template:
    metadata:
      labels:
        k8s-app: web # Used in hubble-ui
    spec:
      containers:
      - name: web
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: xweb
  namespace: default
  annotations:
    metallb.universe.tf/loadBalancerIPs: AZ.201
spec:
  allocateLoadBalancerNodePorts: false
  type: LoadBalancer
  selector:
    k8s-app: web # Used in hubble-ui
  ports:
  - name: tcp-80
    port: 80
    protocol: TCP
    targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: hweb
  namespace: default
spec:
  clusterIP: None
  selector:
    k8s-app: web # Used in hubble-ui
EOF
kubectl apply -f sample.yaml
kubectl expose deployment web --type=NodePort --port=80
kubectl get svc web
kubectl get svc xweb
"@

###

$setup_metallb = @"
echo -e '\U0001F4A1' `$HOSTNAME: setup metallb...
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.5/config/manifests/metallb-native.yaml
sleep 1
cat > metal.yaml <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - AZ.200-AZ.254
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: layer2-lb
  namespace: metallb-system
---
apiVersion: v1
kind: Service
metadata:
  name: coredns-external
  namespace: kube-system
  annotations:
    metallb.universe.tf/loadBalancerIPs: AZ.200
spec:
  allocateLoadBalancerNodePorts: false
  type: LoadBalancer
  selector:
    app.kubernetes.io/instance: rke2-coredns
    app.kubernetes.io/name: rke2-coredns
    k8s-app: kube-dns
  ports:
  - name: udp-53
    port: 53
    protocol: UDP
    targetPort: 53
  - name: tcp-53
    port: 53
    protocol: TCP
    targetPort: 53
EOF
kubectl apply -f metal.yaml
"@

####

$setup_tools = @"
echo -e '\U0001F4A1' `$HOSTNAME: setup tools...
# docker run --rm -it cmd.cat/curl/wget/dig
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
curl -sfSL https://github.com/derailed/k9s/releases/download/v0.26.3/k9s_Linux_x86_64.tar.gz | sudo tar -xz  -C /usr/bin/
curl -LO "https://dl.k8s.io/release/`$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
"@

####

$setup_rancher = @"
echo -e '\U0001F4A1' `$HOSTNAME: setup rancher...
# no support for cgroup2 yet
# docker run --name rancher -d --restart=unless-stopped -p 80:80 -p 443:443 --privileged rancher/rancher:stable

helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
k3s kubectl create namespace cattle-system
kubectl -n cattle-system create secret tls tls-rancher-ingress --cert=/etc/letsencrypt/live/${DOMAIN}/fullchain.pem --key=/etc/letsencrypt/live/${DOMAIN}/privkey.pem
helm install rancher rancher-latest/rancher --set ingress.tls.source=secret --namespace cattle-system --set hostname=rancher.$DOMAIN
# helm uninstall rancher --namespace cattle-system
"@

####

$setup_dns = @"
echo -e '\U0001F4A1' `$HOSTNAME: setup dns...
if grep -q 8.8.8.8 /etc/netplan/01-netcfg.yaml; then
  sudo sed -i 's/8.8.8.8/$MGMT_IP/' /etc/netplan/01-netcfg.yaml
  sudo netplan apply
  sleep 1
fi
"@

####

$setup_ssl = @"
echo -e '\U0001F4A1' `$HOSTNAME: setup ssl...
sudo mkdir -p /var/log/letsencrypt /etc/letsencrypt /var/lib/letsencrypt
sudo chown ${USER}:${USER} /var/log/letsencrypt /etc/letsencrypt /var/lib/letsencrypt

if [ ! -f /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ]; then
  sudo apt update
  sudo apt install -y certbot
  certbot certonly --manual --register-unsafely-without-email --preferred-challenges dns -d *.$DOMAIN
else
  echo -e '\U0001F4A1' `$HOSTNAME: Cert exists. To recreate run: certbot certonly --manual --register-unsafely-without-email --preferred-challenges dns -d *.$DOMAIN
fi

"@

####

# run 9 10 "docker run --rm -it hello-world"
push 9 10 $tmp/Corefile /home/${USER}/Corefile
push 9 10 $tmp/coredns.${DOMAIN}.db /home/${USER}/coredns.${DOMAIN}.db
push 9 10 $tmp/coredns.arpa.db /home/${USER}/coredns.arpa.db
run 9 10 @"
$setup_ssl
$setup_coredns
$setup_dns
$setup_k3s
$setup_tools
$setup_rancher
"@

<#
push 9 10 $tmp/${DOMAIN}.fullchain.pem /home/${USER}/fullchain.pem
push 9 10 $tmp/${DOMAIN}.privkey.pem /home/${USER}/privkey.pem
run 9 10 "sudo mkdir -p /etc/letsencrypt/live/${DOMAIN} && sudo mv /home/${USER}/*.pem /etc/letsencrypt/live/${DOMAIN}/"
#>
pull 9 10 /etc/letsencrypt/live/${DOMAIN}/fullchain.pem $tmp/${DOMAIN}.fullchain.pem
pull 9 10 /etc/letsencrypt/live/${DOMAIN}/privkey.pem $tmp/${DOMAIN}.privkey.pem

run 1 10 @"
$setup_dns
$setup_tools
$setup_rke2
$($setup_metallb.Replace("AZ.","10.111.0."))
$($setup_sample.Replace("AZ.","10.111.0."))
"@

run 2 10 @"
$setup_dns
$setup_tools
$setup_rke2
$($setup_metallb.Replace("AZ.","10.112.0."))
$($setup_sample.Replace("AZ.","10.112.0."))
"@




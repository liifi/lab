#!/bin/sh
# Altered from: https://superuser.com/questions/1354658/hyperv-static-ip-with-vagrant
echo 'Setting static IP address for network...'

cat << EOF > /etc/netplan/99-netcfg-vmware.yaml
network:
  version: 2
  ethernets:
    ens192:
      dhcp4: no
      addresses: [$1]
      routes:
      - to: default
        via: $2
      nameservers:
        addresses: [$3]
EOF

# Be sure NOT to execute "netplan apply" here, so the changes take effect on
# reboot instead of immediately, which would disconnect the provisioner.


###############################

echo "Setting custom dns server '$3' ..."
cat << EOF > /etc/systemd/resolved.conf
[Resolve]
DNS=
FallbackDNS=
Domains=
DNSSEC=yes
#DNSOverTLS=no
#MulticastDNS=no
#LLMNR=no
Cache=yes
#CacheFromLocalhost=no
DNSStubListener=no
"@
EOF

# Do not run systemctl restart systemd-resolved, so the change take effect on
# reboot instead of immediately, which would fail dns requests
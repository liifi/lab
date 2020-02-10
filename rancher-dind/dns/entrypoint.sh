#!/bin/bash

pushd /ws

services=`yq -r ".services|keys|.[]" ./docker-compose.yaml`
hostsfile="
127.0.0.1       localhost
::1     localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
"

echo "$hostsfile"

echo "==== RESOLVING ===="
while IFS= read -r service; do
  ip=`dig +short A $service`
  echo "$ip $service"
  hostsfile="${hostsfile}"$'\n'"$ip $service"
  if [ "$service" = "core" ]; then
    echo "nameserver $ip"
    echo "nameserver $ip" > ./resolv.conf
  fi
done <<< "$services"

echo "==== HOSTS ===="
echo "$hostsfile"
echo "$hostsfile" > ./hosts

coredns
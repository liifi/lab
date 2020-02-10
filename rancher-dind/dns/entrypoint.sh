#!/bin/bash

pushd /ws

services=`yq -r ".services|keys|.[]" ./docker-compose.yaml`
hostsfile=""

echo "==== RESOLVING ===="
while IFS= read -r service; do
  ip=`dig +short A $service`
  echo "$ip $service"
  hostsfile="${hostsfile}"$'\n'"$ip $service"
  if [ "$service" = "core" ]; then
    echo "nameserver $ip"
    echo "# Updated by core" > ./resolv.conf
    echo "nameserver $ip" >> ./resolv.conf
  fi
done <<< "$services"

echo "==== HOSTS ===="
echo "$hostsfile"
echo "$hostsfile" > ./hosts

coredns
#!/bin/bash
set -e
# X forward version

#SSHD
# prepare keys
if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
  # generate fresh rsa key
  ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi
if [ ! -f "/etc/ssh/ssh_host_dsa_key" ]; then
  # generate fresh dsa key
  ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi
#prepare run dir
if [ ! -d "/var/run/sshd" ]; then
  mkdir -p /var/run/sshd
fi

# start sshd
echo "starting ssshd"
/usr/sbin/sshd -D -E /var/log/auth.log &

# reread all config
source /etc/profile

# deploy authorized_keys
if [ ! -z "${AUTHORIZED_KEYS}" ]; then
  echo "${AUTHORIZED_KEYS//$'\n'/\n}" > /root/.ssh/authorized_keys
fi
if [ -f "/identity.pub" ]; then
  cat /identity.pub >> /root/.ssh/authorized_keys
fi

# deploy docker-client-config ( docker registry login)
if [ ! -z "${DOCKER_CLIENT_CONFIG_JSON}" ]; then
  echo ${DOCKER_CLIENT_CONFIG_JSON} > /root/.docker/config.json
fi

if [ "$1" = 'docker' ]; then
  echo "starting docker in client mode (BUSYWAIT), assuming you mounted /var/run/docker.sock from a running docker engine"
  while :; do sleep 1; done
  exit 0
fi

# https://github.com/rancher/rancher/issues/12205
mount --make-rshared /
mount --make-rshared /var/lib/docker

echo "starting dind"
exec /usr/local/bin/dockerd-entrypoint.sh "$@"
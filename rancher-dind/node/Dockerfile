FROM docker:dind

ENV DOCKER_COMPOSE_VERSION 1.22.0

# https://github.com/docker/docker/blob/master/project/PACKAGERS.md#runtime-dependencies
# Adding some basics to make dind ssh friendly and include docker-compose
RUN apk add --no-cache \
    btrfs-progs \
    e2fsprogs \
    e2fsprogs-extra \
    iptables \
    xfsprogs \
    xz \
    py-pip \
    openssh \
    git \
  && pip install --upgrade pip \
  && pip install -U docker-compose==${DOCKER_COMPOSE_VERSION} \
  && rm -rf /root/.cache \
    && chmod +x /usr/local/bin/dind \
  && mkdir -p /root/.docker/ /root/.ssh/ \
  && echo "{}" > /root/.docker/config.json \
  && touch /root/.ssh/authorized_keys \
  && chmod u=rwx,g=,o= /root/.ssh \
  && chmod u=r,g=,o= /root/.ssh/authorized_keys \
  && rm -rf /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_dsa_key

# Specifics
RUN echo "Adding some settings" \
    # Unlock root account
    && sed -ie "s|root:!::0:::::|root:*::0:::::|" /etc/shadow \
    # Install some extra dependencies
    && pip install yq \
    && apk add bash jq bind-tools curl

# get tools
RUN echo "Getting tools" \
    # rancher
    && wget https://github.com/rancher/cli/releases/download/v2.3.2/rancher-linux-amd64-v2.3.2.tar.gz \
    && tar -xzvf rancher-linux-amd64-v2.3.2.tar.gz \
    && mv rancher-v2.3.2/rancher /usr/bin/ \
    && rm -Rf rancher* \
    # rke
    && wget https://github.com/rancher/rke/releases/download/v1.0.4/rke_linux-amd64 -O /usr/bin/rke \
    && chmod +x /usr/bin/rke \
    # kubectl
    && curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin/kubectl \
    # terraform
    && wget https://releases.hashicorp.com/terraform/0.12.12/terraform_0.12.12_linux_amd64.zip \
    && unzip terraform_0.12.12_linux_amd64.zip -d /usr/bin \
    # coredns | for dns server due to dind limitation when spinning up rke cluster
    && wget https://github.com/coredns/coredns/releases/download/v1.6.7/coredns_1.6.7_linux_amd64.tgz \
    && tar -xzvf coredns_1.6.7_linux_amd64.tgz \
    && mv coredns /usr/bin/ \
    && rm -Rf coredns*

COPY node/sshd_config /etc/ssh/sshd_config
COPY node/identity.pub /identity.pub
COPY node/entrypoint.sh /entrypoint.sh
RUN chmod +x /*.sh

EXPOSE 2375 22

#make sure we get fresh keys

ENTRYPOINT ["/entrypoint.sh"]
CMD []
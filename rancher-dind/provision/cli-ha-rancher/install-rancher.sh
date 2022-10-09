#!/bin/bash

# https://rancher.com/docs/rancher/v2.x/en/installation/k8s-install/helm-rancher/
kubectl create namespace cattle-system
kubectl config set-context local --namespace cattle-system # helm 3 had an issue setting namespace, so just to make sure

# Hack because rancher seems to try to deploy an issuer usage
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.13/deploy/manifests/00-crds.yaml

helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set ingress.tls.source=rancher \
  --version 2.2.8 \
  --set hostname=node-4
#!/usr/bin/env bash
# Patch the health checks into argocd-cm. No args = all checks; or name them to add one live:
#   scripts/apply-config.sh ConfigMap
# The controller picks up argocd-cm changes without a restart.
cd "$(dirname "$0")/.."
scripts/build-cm.sh "$@" > /tmp/healthdemo-cm-patch.yaml
kubectl --context kind-healthdemo -n argocd patch configmap argocd-cm --type merge --patch-file /tmp/healthdemo-cm-patch.yaml

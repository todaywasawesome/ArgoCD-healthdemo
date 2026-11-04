#!/usr/bin/env bash
# Assemble argocd-config/health/<key>.lua into a ConfigMap patch (stdout).
# Usage: build-cm.sh [check ...]   (no args = all checks; a check is the file name without .lua)
cd "$(dirname "$0")/.."
checks=("$@"); [ ${#checks[@]} -eq 0 ] && checks=($(cd argocd-config/health && ls *.lua | sed 's/\.lua$//'))
args=(); for c in "${checks[@]}"; do args+=(--from-file="resource.customizations.health.$c=argocd-config/health/$c.lua"); done
kubectl create configmap argocd-cm "${args[@]}" --dry-run=client -o yaml \
  | sed -e '/creationTimestamp/d' | sed -e 's/^  name: argocd-cm/  name: argocd-cm\n  labels:\n    app.kubernetes.io\/name: argocd-cm\n    app.kubernetes.io\/part-of: argocd/'

#!/usr/bin/env bash
# Usage: set-widget-status.sh <name> <ready|failed|reconciling> [namespace]
# Plays the role of the missing Widget controller by patching the status subresource.
set -euo pipefail
name=${1:?widget name}; state=${2:?ready|failed|reconciling}
ns=${3:-$(kubectl --context kind-healthdemo get widgets.healthdemo.example.io -A -o json | jq -r --arg n "$name" '.items[]|select(.metadata.name==$n)|.metadata.namespace' | head -1)}
gen=$(kubectl --context kind-healthdemo -n "$ns" get widget "$name" -o jsonpath='{.metadata.generation}')
case $state in
  ready)       conds='[{"type":"Ready","status":"True","reason":"Reconciled","message":"Widget is ready"}]'; og=$gen ;;
  failed)      conds='[{"type":"Ready","status":"False","reason":"BackendUnavailable","message":"Backend unavailable: cannot allocate widget"}]'; og=$gen ;;
  reconciling) conds='[]'; og=$((gen-1)) ;;
  *) echo "state must be ready|failed|reconciling" >&2; exit 2 ;;
esac
kubectl --context kind-healthdemo -n "$ns" patch widget "$name" --subresource=status --type merge \
  -p "{\"status\":{\"observedGeneration\":$og,\"conditions\":$conds}}"

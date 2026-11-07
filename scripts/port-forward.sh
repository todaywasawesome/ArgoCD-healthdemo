#!/usr/bin/env bash
# Background port-forward of the Argo CD API server to localhost:8080 (idempotent).
cd "$(dirname "$0")/.."
if curl -ksf -o /dev/null https://localhost:8080/healthz; then exit 0; fi
nohup kubectl --context kind-healthdemo -n argocd port-forward svc/argocd-server 8080:443 >/tmp/healthdemo-pf.log 2>&1 &
for i in $(seq 30); do curl -ksf -o /dev/null https://localhost:8080/healthz && exit 0; sleep 1; done
echo "port-forward failed" >&2; exit 1

#!/usr/bin/env bash
# One line per check. Exit non-zero if any fail.
cd "$(dirname "$0")/.."
K="kubectl --context kind-healthdemo"; rc=0
ok(){ printf 'OK    %s\n' "$1"; }; bad(){ printf 'FAIL  %s\n' "$1"; rc=1; }
chk(){ local name=$1; shift; if "$@" >/dev/null 2>&1; then ok "$name"; else bad "$name"; fi; }
set -a; source .demo-credentials 2>/dev/null || bad ".demo-credentials missing" ; set +a
chk "kind cluster healthdemo exists"        bash -c 'kind get clusters | grep -qx healthdemo'
chk "both nodes Ready"                      bash -c "[ \$($K get nodes --no-headers | grep -cw Ready) -eq 2 ]"
chk "Argo CD deployments available"         $K -n argocd wait --for=condition=Available deploy --all --timeout=5s
chk "application controller ready"          bash -c "[ \"\$($K -n argocd get sts argocd-application-controller -o jsonpath='{.status.readyReplicas}')\" = 1 ]"
chk "port-forward https://localhost:8080"   curl -ksf -o /dev/null https://localhost:8080/healthz
chk "demo-agent token valid"                bash -c "curl -ksf -H \"Authorization: Bearer \$DEMO_AGENT_TOKEN\" https://localhost:8080/api/v1/applications | jq -e '.items|length>=4'"
chk "admin login works"                     argocd login localhost:8080 --username "$ARGOCD_ADMIN_USER" --password "$ARGOCD_ADMIN_PASSWORD" --insecure
chk "Widget CRD installed"                  $K get crd widgets.healthdemo.example.io
chk "repo reachable from Argo CD"           bash -c "argocd repo list -o json | jq -e '.[0].connectionState.status==\"Successful\"'"
for img in $(cat scripts/images.txt); do
  for node in healthdemo-control-plane healthdemo-worker; do
    chk "image $img on $node"               bash -c "docker exec $node crictl images -o json | jq -e --arg i '$img' '[.images[].repoTags[]] | index(\$i)'"
  done
done
exit $rc

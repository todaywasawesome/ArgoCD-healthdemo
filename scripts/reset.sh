#!/usr/bin/env bash
# Return cluster and Git to the opening state: no custom health checks, demo-live == demo-build,
# apps recreated; config/widget/lb synced, wave-demo left OutOfSync for Demo C.
set -euo pipefail
cd "$(dirname "$0")/.."
start=$(date +%s)
K="kubectl --context kind-healthdemo"
export GIT_TOKEN="${GIT_TOKEN:-$(tr -d '[:space:]' < GIT_TOKEN)}" GIT_ASKPASS="$PWD/scripts/git-askpass.sh" GIT_TERMINAL_PROMPT=0
APPS="config-demo widget-demo wave-demo lb-demo"

scripts/port-forward.sh
source .demo-credentials
argocd login localhost:8080 --username "$ARGOCD_ADMIN_USER" --password "$ARGOCD_ADMIN_PASSWORD" --insecure >/dev/null

echo "== delete apps"
$K -n argocd delete applications.argoproj.io $APPS --ignore-not-found --wait=true --timeout=90s >/dev/null
$K delete ns $APPS --ignore-not-found --wait=true --timeout=90s >/dev/null

echo "== remove custom health checks from argocd-cm"
patch=$($K -n argocd get cm argocd-cm -o json | jq -c '{data: ((.data // {}) | with_entries(select(.key|startswith("resource.customizations.health."))) | map_values(null))}')
[ "$patch" != '{"data":{}}' ] && $K -n argocd patch cm argocd-cm --type merge -p "$patch" >/dev/null

echo "== cluster prerequisites"
$K apply -f crds/widget-crd.yaml >/dev/null
$K -n argocd patch cm argocd-cm --type merge --patch-file argocd-config/accounts-cm-patch.yaml >/dev/null
$K -n argocd patch cm argocd-rbac-cm --type merge --patch-file argocd-config/rbac-cm-patch.yaml >/dev/null
scripts/repo-secret.sh >/dev/null

echo "== restore Git: demo-live <- demo-build ($(git rev-parse --short demo-build))"
git push -q --force origin refs/heads/demo-build:refs/heads/demo-live

echo "== recreate apps"
$K apply -f argocd-apps/ >/dev/null
for a in config-demo widget-demo lb-demo; do
  argocd app sync "$a" --timeout 60 >/dev/null
done
argocd app get wave-demo --refresh >/dev/null
argocd app list -o wide 2>/dev/null | awk '{print $1, $5, $6}' | column -t
echo "reset done in $(( $(date +%s) - start ))s"

#!/usr/bin/env bash
# Offline test of every health check: runs each fixtures/<name>.yaml through the Argo CD CLI
# against the assembled argocd-cm and compares STATUS with fixtures/<name>.expected.
cd "$(dirname "$0")/.."
scripts/build-cm.sh > argocd-config/argocd-cm.yaml
fail=0
for f in fixtures/*.yaml; do
  n=${f%.yaml}; want=$(cat "$n.expected")
  got=$(KUBECONFIG=/dev/null argocd admin settings resource-overrides health "$f" \
        --argocd-cm-path argocd-config/argocd-cm.yaml 2>/dev/null | sed -n 's/^STATUS: //p')
  if [ "$got" = "$want" ]; then echo "PASS $(basename "$n"): $got"; else echo "FAIL $(basename "$n"): want $want got ${got:-<none>}"; fail=1; fi
done
exit $fail

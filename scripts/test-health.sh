#!/usr/bin/env bash
# Offline test of every health check: runs each fixtures/<name>.yaml through the Argo CD CLI
# against the assembled argocd-cm and compares STATUS with fixtures/<name>.expected.
cd "$(dirname "$0")/.."
scripts/build-cm.sh > argocd-config/argocd-cm.yaml
fail=0
for f in fixtures/*.yaml; do
  # <name>.expected: line 1 = status, optional line 2 = text the message must contain
  n=${f%.yaml}; want=$(sed -n 1p "$n.expected"); want_msg=$(sed -n 2p "$n.expected")
  out=$(KUBECONFIG=/dev/null argocd admin settings resource-overrides health "$f" \
        --argocd-cm-path argocd-config/argocd-cm.yaml 2>/dev/null)
  got=$(sed -n 's/^STATUS: //p' <<<"$out"); msg=$(sed -n 's/^MESSAGE: //p' <<<"$out")
  if [ -n "$want_msg" ] && [[ "$msg" != *"$want_msg"* ]]; then got="$got (message '$msg')"; fi
  if [ "$got" = "$want" ]; then echo "PASS $(basename "$n"): $got"; else echo "FAIL $(basename "$n"): want $want got ${got:-<none>}"; fail=1; fi
done
exit $fail

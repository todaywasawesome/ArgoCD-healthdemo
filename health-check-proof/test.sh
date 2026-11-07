#!/usr/bin/env bash
# Runs each fixture through the argocd CLI with no cluster (KUBECONFIG=/dev/null) and
# compares STATUS with the expected value. Exits non-zero on any mismatch.
cd "$(dirname "$0")"
export KUBECONFIG=/dev/null
kubectl get ns >/dev/null 2>&1 && { echo "a cluster is reachable; refusing to run"; exit 2; }
echo "no cluster reachable (kubectl get ns fails with KUBECONFIG=/dev/null)"
fail=0
for pair in healthy:Healthy degraded:Degraded unlabeled:Healthy empty:Healthy; do
  f=${pair%%:*}; want=${pair#*:}
  got=$(argocd admin settings resource-overrides health "./$f.yaml" --argocd-cm-path ./argocd-cm.yaml 2>/dev/null | sed -n 's/^STATUS: //p')
  if [ "$got" = "$want" ]; then echo "PASS $f: $got"; else echo "FAIL $f: want $want, got ${got:-<none>}"; fail=1; fi
done
exit $fail

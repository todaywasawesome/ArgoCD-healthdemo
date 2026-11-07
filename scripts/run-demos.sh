#!/usr/bin/env bash
# Run Demos A-D from the opening state (run scripts/reset.sh first), asserting each state the
# talk shows. Writes the real output to demo/out/<demo>.txt. Exits non-zero on the first failure.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p demo/out
export PATH="$PWD/scripts:$PATH"

run() { echo "\$ $*" >&2; "$@" 2>&1; }
# expect <app> <app-health> [text the health.sh output must contain]  (polls up to 60s)
expect() {
  local app=$1 want=$2 text=${3:-} out
  for _ in $(seq 30); do
    out=$(health.sh "$app" refresh 2>&1)
    if grep -q "^app $app: .* / $want\$" <<<"$out" && { [ -z "$text" ] || grep -qF -- "$text" <<<"$out"; }; then
      echo "\$ scripts/health.sh $app"; echo "$out"; return 0
    fi
    sleep 2
  done
  echo "\$ scripts/health.sh $app"; echo "$out"; echo "FAIL: $app expected $want ${text:+with '$text'}"; return 1
}

demo_A() {
  run apply-config.sh ConfigMap
  expect config-demo Healthy "ConfigMap ok" || return 1
  run set-demo-state.sh broken
  run argocd app sync config-demo --timeout 60 -o tree >/dev/null
  expect config-demo Degraded "DEMO_STATE is broken: set it to ok and sync again" || return 1
  run set-demo-state.sh ok
  run argocd app sync config-demo --timeout 60 -o tree >/dev/null
  expect config-demo Healthy "ConfigMap ok"
}

demo_B() {
  expect widget-demo Healthy || return 1   # no check yet: Argo CD ignores the Widget
  run apply-config.sh healthdemo.example.io_Widget
  expect widget-demo Progressing "Waiting for controller to reconcile" || return 1
  run set-widget-status.sh demo-widget failed
  expect widget-demo Degraded "Backend unavailable: cannot allocate widget" || return 1
  run set-widget-status.sh demo-widget ready
  expect widget-demo Healthy "Widget is ready"
}

demo_C() {
  run apply-config.sh healthdemo.example.io_Widget
  local t0 t1 t2; t0=$(date +%s)
  run argocd app sync wave-demo --async
  expect wave-demo Progressing "waiting for healthy state of healthdemo.example.io/Widget/wave-widget" || return 1
  sleep 5
  expect wave-demo Progressing "operation: Running" || return 1
  t1=$(date +%s)
  run set-widget-status.sh wave-widget ready
  run argocd app wait wave-demo --sync --health --timeout 120 >/dev/null || return 1
  t2=$(date +%s)
  expect wave-demo Healthy "operation: Succeeded" || return 1
  echo "TIMING: wave 1 held for $((t1-t0))s (until the Widget turned Ready); wave 1 done $((t2-t1))s after Ready"
}

demo_D() {
  expect lb-demo Progressing "Service/public-web: Progressing - " || return 1
  run kubectl --context kind-healthdemo -n lb-demo get svc public-web
  run apply-config.sh Service
  expect lb-demo Progressing "Waiting for an external address: is a load balancer controller installed?"
}

rc=0
for d in A B C D; do
  if "demo_$d" > "demo/out/$d.txt" 2>&1; then echo "PASS demo $d"; else echo "FAIL demo $d (see demo/out/$d.txt)"; rc=1; fi
done
exit $rc

#!/usr/bin/env bash
# Writes db-recent.yaml (Ready=False 2 min ago) and db-old.yaml (Ready=False 30 min ago),
# with lastTransitionTime in UTC relative to now.
cd "$(dirname "$0")"
gen() { cat > "$1" <<YAML
apiVersion: example.io/v1
kind: Database
metadata:
  name: orders-db
status:
  conditions:
    - type: Ready
      status: "False"
      reason: Provisioning
      lastTransitionTime: "$(date -u -v-"$2" +%Y-%m-%dT%H:%M:%SZ)"
YAML
}
gen db-recent.yaml 2M
gen db-old.yaml 30M
grep -H lastTransitionTime db-recent.yaml db-old.yaml

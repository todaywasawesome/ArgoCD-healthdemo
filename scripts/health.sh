#!/usr/bin/env bash
# One line per resource: kind/name: health - message (the message column `argocd app get` hides).
argocd app get "${1:?app}" ${2:+--refresh} -o json | jq -r '"app \(.metadata.name): \(.status.sync.status) / \(.status.health.status)", (.status.resources[] | "  \(.kind)/\(.name): \(.health.status // "-") - \(.health.message // "")")'

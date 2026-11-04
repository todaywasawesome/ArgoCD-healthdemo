#!/usr/bin/env bash
# Commit DEMO_STATE=<ok|broken> for config-demo to the demo-live branch (what the presenter
# would otherwise do in an editor). Uses a git-ignored worktree at .live/.
set -euo pipefail
cd "$(dirname "$0")/.."
state=${1:?ok|broken}
export GIT_TOKEN="${GIT_TOKEN:-$(tr -d '[:space:]' < GIT_TOKEN)}" GIT_ASKPASS="$PWD/scripts/git-askpass.sh" GIT_TERMINAL_PROMPT=0
git fetch -q origin demo-live
[ -d .live ] || git worktree add -q --detach .live origin/demo-live
cd .live && git checkout -q --detach origin/demo-live
sed -i.bak -E "s/DEMO_STATE: .*/DEMO_STATE: $state/" apps/config-demo/configmap.yaml && rm -f apps/config-demo/configmap.yaml.bak
git diff --quiet && { echo "DEMO_STATE already $state"; exit 0; }
# demo-live is throwaway (reset.sh force-pushes it), so skip signing: no 1Password prompt mid-talk
git -c commit.gpgsign=false commit -qam "config-demo: DEMO_STATE=$state"
git push -q origin HEAD:demo-live && echo "pushed DEMO_STATE=$state to demo-live ($(git rev-parse --short HEAD))"

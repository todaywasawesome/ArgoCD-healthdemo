#!/usr/bin/env bash
# For screenshots: serve a one-shot page on http://localhost:8099 that sets the argocd.token
# cookie for host "localhost" (cookies ignore ports, so https://localhost:8080 gets it).
# Keeps the session token out of Playwright code. Stop with: pkill -f "http.server 8099"
cd "$(dirname "$0")/.."
set -a; source .demo-credentials; set +a
d=$(mktemp -d); chmod 700 "$d"
tok=$(curl -ks https://localhost:8080/api/v1/session -H 'Content-Type: application/json' \
  -d "$(jq -nc --arg u "$ARGOCD_ADMIN_USER" --arg p "$ARGOCD_ADMIN_PASSWORD" '{username:$u,password:$p}')" | jq -r .token)
printf '<script>document.cookie="argocd.token=%s; path=/";document.write("ok")</script>' "$tok" > "$d/index.html"
(cd "$d" && nohup python3 -m http.server 8099 --bind 127.0.0.1 >/dev/null 2>&1 &)
sleep 1; echo "cookie server up ($d)"

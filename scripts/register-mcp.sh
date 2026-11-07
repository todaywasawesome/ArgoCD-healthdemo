#!/usr/bin/env bash
# Register the Argo CD MCP server (argoproj-labs/mcp-for-argocd, npm argocd-mcp) with Claude Code
# for this folder. Local scope = stored in the user's Claude config, not in the repo. The
# demo-agent token comes from the git-ignored .demo-credentials.
cd "$(dirname "$0")/.."
set -a; source .demo-credentials; set +a
claude mcp remove argocd -s local >/dev/null 2>&1
claude mcp add argocd -s local \
  -e ARGOCD_BASE_URL=https://localhost:8080 \
  -e ARGOCD_API_TOKEN="$DEMO_AGENT_TOKEN" \
  -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
  -- npx -y argocd-mcp@0.9.0 stdio >/dev/null && echo "registered argocd MCP (argocd-mcp@0.9.0)"

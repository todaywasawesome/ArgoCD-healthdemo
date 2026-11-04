# Agent prompt (Demo E: agent fixes config-demo through the Argo CD MCP server)

Setup before the talk segment:

```
scripts/register-mcp.sh                 # once per machine; restart Claude Code afterwards
scripts/apply-config.sh ConfigMap       # the check the agent will read
scripts/set-demo-state.sh broken && argocd app sync config-demo   # scripted starting state
```

Paste this into Claude Code, started in the repo folder:

---

The Argo CD application `config-demo` is unhealthy. Use the `argocd` MCP server to read the
application's health status and the health message of each resource, and work out the cause.
The app is deployed from this Git repository, path `apps/config-demo`, branch `demo-live`
(work in a checkout of `origin/demo-live`, for example `git worktree add .live origin/demo-live`
if `.live/` does not exist). Fix the cause in Git, commit with `git -c commit.gpgsign=false commit`
(demo-live is a throwaway branch), and push to `demo-live`. Then sync
`config-demo` through the MCP server and confirm it reports Healthy. Do not use kubectl or the
argocd CLI, and do not change anything else.

---

What a good run looks like: `get_application` shows ConfigMap `demo-settings` Degraded with
"DEMO_STATE is broken: set it to ok and sync again" → agent edits `DEMO_STATE: ok` → pushes →
`sync_application` → `get_application` shows Healthy.

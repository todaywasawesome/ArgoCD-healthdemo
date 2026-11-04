#!/usr/bin/env bash
# Registers the private repo with Argo CD. Token comes from the GIT_TOKEN env var (or the
# git-ignored GIT_TOKEN file) over stdin, so it never appears in argv, a file in the repo, or logs.
cd "$(dirname "$0")/.."
: "${GIT_TOKEN:=$(tr -d '[:space:]' < GIT_TOKEN)}"
kubectl --context kind-healthdemo apply -f - >/dev/null <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: repo-healthdemo
  namespace: argocd
  labels: {argocd.argoproj.io/secret-type: repository}
stringData:
  type: git
  url: https://github.com/todaywasawesome/ArgoCD-healthdemo.git
  username: todaywasawesome
  password: "$GIT_TOKEN"
YAML
echo "repo secret applied"

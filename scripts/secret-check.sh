#!/usr/bin/env bash
# Fails if staged changes contain a token prefix or the literal value of the token file.
# (The bare name GIT_TOKEN is allowed: .gitignore and the askpass helper reference it.)
cd "$(dirname "$0")/.."
d=$(git diff --cached -- . ':!scripts/secret-check.sh')
if grep -q -i -E 'ghp_|github_pat_' <<<"$d"; then echo "secret-check: token prefix found" >&2; exit 1; fi
if [ -s GIT_TOKEN ] && grep -qF -- "$(tr -d '[:space:]' < GIT_TOKEN)" <<<"$d"; then echo "secret-check: token value found" >&2; exit 1; fi
echo "secret-check: clean"

#!/bin/sh
# GIT_ASKPASS helper: answers git's prompts from the GIT_TOKEN env var (never written to disk or URLs)
case "$1" in
  Username*) echo "todaywasawesome" ;;
  *) printf '%s' "$GIT_TOKEN" ;;
esac

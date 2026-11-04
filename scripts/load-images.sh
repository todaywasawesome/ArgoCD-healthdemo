#!/usr/bin/env bash
# Pull every image in images.txt (arm64/host platform) and load into kind. Offline safety.
set -euo pipefail
cd "$(dirname "$0")/.."
plat="linux/$(docker info --format '{{.Architecture}}' | sed 's/aarch64/arm64/;s/x86_64/amd64/')"
tmp=$(mktemp -d); trap 'rm -rf $tmp' EXIT
while read -r img; do
  [ -z "$img" ] && continue
  docker pull -q --platform "$plat" "$img" >/dev/null
  docker save --platform "$plat" -o "$tmp/i.tar" "$img"
  kind load image-archive --name healthdemo "$tmp/i.tar" >/dev/null
  echo "loaded $img"
done < scripts/images.txt

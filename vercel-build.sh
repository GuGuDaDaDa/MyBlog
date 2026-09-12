#!/bin/bash
# Vercel build script: install the pinned Hugo version, then build the site.
set -euo pipefail

HUGO_VERSION="${HUGO_VERSION:-0.166.0}"
BIN="$HOME/.local/bin"
mkdir -p "$BIN"

if [ ! -x "$BIN/hugo" ]; then
  curl -fsSL "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz" \
    | tar -xz -C "$BIN" hugo
  chmod +x "$BIN/hugo"
fi

ARGS="--gc --minify"

# 预览/分支部署使用 Vercel 分配的临时域名，避免指向正式域名
if [ "${VERCEL_ENV:-production}" != "production" ] && [ -n "${VERCEL_URL:-}" ]; then
  ARGS="$ARGS -b https://$VERCEL_URL --buildFuture"
fi

exec "$BIN/hugo" $ARGS

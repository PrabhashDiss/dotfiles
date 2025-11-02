#!/usr/bin/env bash

set -euo pipefail

log() { >&2 echo "$*"; }

require_groq_key() {
  if [ -z "${GROQ_API_KEY:-}" ]; then
    log "Error: GROQ_API_KEY environment variable not set."
    exit 1
  fi
}

ensure_deps() {
  local miss=0
  for cmd in jq curl mktemp; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log "Error: '$cmd' command not found in PATH."
      miss=1
    fi
  done
  if [ "$miss" -ne 0 ]; then
    exit 1
  fi
}

groq_call() {
  require_groq_key

  local payload="$1"
  curl -s "$GROQ_URL" \
    -H "Authorization: Bearer $GROQ_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload"
}

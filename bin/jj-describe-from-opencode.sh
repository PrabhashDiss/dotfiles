#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/../lib/editor-helper.sh"

# Parse args
revset=""
while [[ $# -gt 0 ]]; do
  arg="$1"
  case "$arg" in
    -r|--revset)
      if [[ $# -lt 2 ]]; then
        echo "Error: revset is required"
        exit 1
      fi
      revset="$2"
      shift 2
  esac
done

generated_msg=$(opencode run --command generate-describe-msg $revset)
edited_msg=$(quick_edit "$generated_msg")

jj describe -m "$edited_msg" -r "$revset"

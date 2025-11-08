#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/../lib/editor-helper.sh"

# Parse args
from=""
while [[ $# -gt 0 ]]; do
  arg="$1"
  case "$arg" in
    -f|--from)
      if [[ $# -lt 2 ]]; then
        echo "Error: from is required"
        exit 1
      fi
      from="$2"
      shift 2
  esac
done

generated_name=$(opencode run --command generate-bookmark-name $from)
edited_name=$(quick_edit "$generated_name")

jj bookmark create "$edited_name"

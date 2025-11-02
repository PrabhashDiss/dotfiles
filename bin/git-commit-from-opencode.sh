#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/../lib/editor-helper.sh"

generated_msg=$(opencode run --command generate-commit-msg)
edited_msg=$(quick_edit "$generated_msg")

git commit -m "$edited_msg"

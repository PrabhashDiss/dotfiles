#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/../lib/editor-helper.sh"

# Parse args
head_branch=""
base_branch=""
while [[ $# -gt 0 ]]; do
  arg="$1"
  case "$arg" in
    -h|--head)
      if [[ $# -lt 2 ]]; then
        echo "Error: head branch is required"
        exit 1
      fi
      head_branch="$2"
      shift 2
      ;;
    -b|--base)
      if [[ $# -lt 2 ]]; then
        echo "Error: base branch is required"
        exit 1
      fi
      base_branch="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $arg"
      exit 1
      ;;
  esac
done

if [ -z "$head_branch" ]; then
  head_branch=$(git branch --show-current)
fi

if [ -z "$base_branch" ]; then
  base_branch="develop"
fi

generated_msg=$(opencode run --command generate-pr-msg "$base_branch...$head_branch")
edited_msg=$(quick_edit "$generated_msg")

# Parse title and body from edited message
new_title=$(echo "$edited_msg" | awk 'NR==1{print; exit}' | sed 's/[\r\n]*$//')
new_body=$(echo "$edited_msg" | awk 'NR>1{print}' | sed '1{/^$/d;}' | sed -e 's/^\n*//')

gh pr create \
  --title "$new_title" \
  --body "$new_body" \
  --base "$base_branch" \
  --head "$head_branch"

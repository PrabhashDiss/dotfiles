#!/usr/bin/env bash
set -euo pipefail

log() { >&2 echo "[git-wt-from-diff] $*"; }

# --- Configuration ---------------------------------------------------
GROQ_MODEL="moonshotai/kimi-k2-instruct-0905"
GROQ_URL="https://api.groq.com/openai/v1/chat/completions"

# --- Helper ----------------------------------------------------------
groq_get_branch() {
  if [ -z "${GROQ_API_KEY:-}" ]; then
    log "Error: GROQ_API_KEY environment variable not set."
    exit 1
  fi

  local diff_input
  diff_input=$(cat)

  # Build JSON payload using jq for proper escaping
  local payload
  payload=$(jq -n --arg model "$GROQ_MODEL" --arg diff "$diff_input" '{
    model: $model,
    messages: [
      {
        role: "system",
        content: "You are a git assistant. Given a git diff, generate a concise, kebab-case branch name in the format '\''<type>/<topic>'\''. Examples: '\''feat/add-login'\'', '\''fix/null-pointer'\'', '\''chore/update-docs'\''."
      },
      {
        role: "user",
        content: $diff
      }
    ],
    response_format: {
      type: "json_schema",
      json_schema: {
        name: "branch_name",
        schema: {
          type: "object",
          properties: {
            branch: { type: "string" }
          },
          required: ["branch"],
          additionalProperties: false
        }
      }
    }
  }')

  # Call Groq API
  local response
  response=$(curl -s "$GROQ_URL" \
    -H "Authorization: Bearer $GROQ_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload")

  # Extract branch name
  local branch_name
  branch_name=$(echo "$response" | jq -r '.choices[0].message.content // empty' | jq -r '.branch // empty')

  if [ -z "$branch_name" ]; then
    log "Error: No branch name returned."
    echo "$response" >&2
    exit 1
  fi

  echo "$branch_name"
}

# --- Main script -----------------------------------------------------

# Ensure we are in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  log "Not inside a git repository."
  exit 1
fi

# Get staged diff
staged_diff=$(git diff --cached)
if [ -z "$staged_diff" ]; then
  log "No staged changes found."
  exit 1
fi

# Generate branch name via Groq
branch_name=$(printf "%s" "$staged_diff" | groq_get_branch)
log "Groq suggested branch: $branch_name"

# Validate branch name format
if ! [[ "$branch_name" =~ ^[^/]+/[^/]+$ ]]; then
  log "Invalid branch name format: '$branch_name'. Expected '<type>/<topic>'."
  exit 1
fi

# Stash the staged changes
stash_msg="auto-stash-for-$branch_name"
git stash push --staged -m "$stash_msg"
stash_ref="stash@{0}"
log "Stashed staged changes as $stash_ref"

# Compute safe worktree path (replace / with -)
safe_path=${branch_name//\//-}
new_path="../$safe_path"

# Create the new worktree & branch
git worktree add -b "$branch_name" "$new_path" HEAD
log "Created new worktree: $new_path (branch: $branch_name)"

# Move into it
cd "$new_path"
log "Changed directory to $new_path"

# Pop + re-stage the stash
if git stash list --format="%s" | grep "$stash_msg"; then
  log "Popping stash in new worktree..."
  if git stash pop --index; then
    log "Stash reapplied and staged successfully."
  else
    log "Conflict or failure applying stash. Trying fallback apply..."
    git stash apply --index || git stash apply || log "Manual merge may be needed."
  fi
else
  log "No stash found with message '$stash_msg'."
fi

log "Done. Now on branch '$branch_name' in '$new_path' with your changes staged."

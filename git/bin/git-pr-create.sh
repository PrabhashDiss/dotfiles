#!/usr/bin/env bash
set -euo pipefail

log() { >&2 echo "[git-pr-from-branch] $*"; }

# --- Configuration ---------------------------------------------------
GROQ_MODEL="moonshotai/kimi-k2-instruct-0905"
GROQ_URL="https://api.groq.com/openai/v1/chat/completions"
BASE_BRANCH="develop"

# --- Helper ----------------------------------------------------------
groq_get_pr_details() {
  if [ -z "${GROQ_API_KEY:-}" ]; then
    log "Error: GROQ_API_KEY environment variable not set."
    exit 1
  fi

  local diff_input
  diff_input=$(cat)

  local payload
  payload=$(jq -n --arg model "$GROQ_MODEL" --arg diff "$diff_input" '{
    model: $model,
    messages: [
      {
        role: "system",
        content: "You are a git assistant. Given a git diff, generate a PR title and body. Title format: '\''[ticket-id] type(scope): description'\'' following Conventional Commit guidelines (types: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test). Body should summarize changes, purpose, and context."
      },
      {
        role: "user",
        content: $diff
      }
    ],
    response_format: {
      type: "json_schema",
      json_schema: {
        name: "pr_details",
        schema: {
          type: "object",
          properties: {
            title: { type: "string" },
            body: { type: "string" }
          },
          required: ["title", "body"],
          additionalProperties: false
        }
      }
    }
  }')

  local response
  response=$(curl -s "$GROQ_URL" \
    -H "Authorization: Bearer $GROQ_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload")

  echo "$response" | jq -r '.choices[0].message.content'
}

# --- Main script -----------------------------------------------------

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  log "Not inside a git repository."
  exit 1
fi

# Get current branch
current_branch=$(git branch --show-current)
log "Current branch: $current_branch"

# Get diff between current branch and base
branch_diff=$(git diff "$BASE_BRANCH"...HEAD)

if [ -z "$branch_diff" ]; then
  log "No changes between $current_branch and $BASE_BRANCH."
  exit 1
fi

# Generate PR details via Groq
log "Generating PR details..."
pr_json=$(printf "%s" "$branch_diff" | groq_get_pr_details)

pr_title=$(echo "$pr_json" | jq -r '.title')
pr_body=$(echo "$pr_json" | jq -r '.body')

log "PR Title: $pr_title"
log "Creating pull request..."

# Create PR using gh
gh pr create \
  --title "$pr_title" \
  --body "$pr_body" \
  --base "$BASE_BRANCH" \
  --head "$current_branch"

log "Pull request created successfully!"

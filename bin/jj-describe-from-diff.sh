#!/usr/bin/env bash
set -euo pipefail

log() { >&2 echo "$*"; }

# --- Configuration ---------------------------------------------------
GROQ_MODEL="moonshotai/kimi-k2-instruct-0905"
GROQ_URL="https://api.groq.com/openai/v1/chat/completions"

# --- Helpers ---------------------------------------------------------
require_groq_key() {
  if [ -z "${GROQ_API_KEY:-}" ]; then
    log "Error: GROQ_API_KEY environment variable not set."
    exit 1
  fi
}

check_deps() {
  for cmd in jj jq curl mktemp; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log "Error: '$cmd' command not found in PATH."
      exit 1
    fi
  done
}

# Call Groq to generate a commit/description from a diff
groq_generate_description() {
  local diff_input
  diff_input=$(cat)

  # Build payload with jq for safe escaping
  local payload
  payload=$(jq -n --arg model "$GROQ_MODEL" --arg diff "$diff_input" '{
    model: $model,
    messages: [
      { role: "system", content: "You are a version-control assistant. Given a jj diff, produce a concise commit message subject (max 72 chars) and a detailed body explaining the changes, motivation, and any notes for reviewers. Return JSON with keys: subject, body." },
      { role: "user", content: $diff }
    ],
    response_format: {
      type: "json_schema",
      json_schema: {
        name: "description",
        schema: {
          type: "object",
          properties: {
            subject: { type: "string" },
            body: { type: "string" }
          },
          required: ["subject","body"],
          additionalProperties: false
        }
      }
    }
  }')

  log "Groq request payload:"
  log "$payload"

  local response
  response=$(curl -s "$GROQ_URL" \
    -H "Authorization: Bearer $GROQ_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload")

  echo "$response"
}

# --- Main ------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $(basename "$0") -r REVSET|--revset REVSET

Generate a description for changes in a given revset. The revset is
required and will be passed to 'jj diff --revset=REVSET'.
The generated description is opened in nvim (or \$EDITOR) for editing; when
you save and exit, the final subject and body are printed to stdout.

Examples:
  $(basename "$0") --revset "@..~"    # diff for a revset
  $(basename "$0") -r "@..~"         # short form
EOF
}

# Parse args
revset=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--revset)
      if [[ "$1" == *=* ]]; then
        revset="${1#*=}"
        shift
      else
        revset="${2:-}"
        shift 2
      fi
      ;;
    --revset=*) revset="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) log "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

if [ -z "$revset" ]; then
  log "Error: revset is required."
  usage
  exit 1
fi

require_groq_key
check_deps

# Collect diff for the revset
jj_args=("-r" "$revset")

diff_output=$(jj diff "${jj_args[@]}" 2>/dev/null || true)
if [ -z "$diff_output" ]; then
  log "No jj diff found for revset: $revset"
  exit 0
fi

# Generate description via Groq (pass diff via stdin)
groq_response=$(printf "%s" "$diff_output" | groq_generate_description)

# Extract the JSON from the Groq response
json_content=$(echo "$groq_response" | jq -r '.choices[0].message.content // empty')
if [ -z "$json_content" ]; then
  log "Error: Groq did not return content. Full response:"
  echo "$groq_response" >&2
  exit 1
fi

# Validate JSON and extract fields
subject=$(printf "%s" "$json_content" | jq -r '.subject // empty')
body=$(printf "%s" "$json_content" | jq -r '.body // empty')
if [ -z "$subject" ] || [ -z "$body" ]; then
  log "Error: Groq response missing subject or body. Response content:"
  echo "$json_content" >&2
  exit 1
fi

# Create temp file and prefill with subject/body
tmpfile=$(mktemp --suffix=.jj-desc)
cat > "$tmpfile" <<EOF
$subject

$body
EOF

# Open in editor for editing
${EDITOR:-nvim} "$tmpfile"

# After edit, read back
final_subject=$(sed -n '1p' "$tmpfile" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
final_body=$(tail -n +3 "$tmpfile")

# Output
cat <<EOF
Subject: $final_subject

$final_body
EOF

# Apply description to the revset using jj describe
message=$(printf "%s\n\n%s\n" "$final_subject" "$final_body")
if printf "%s" "$message" | jj describe --stdin "$revset" >/dev/null 2>&1; then
  log "Description applied to revset: $revset"
else
  log "Warning: failed to apply description to revset: $revset"
  log "You can manually run: printf \"%s\\n\\n%s\\n\" \"$final_subject\" \"$final_body\" | jj describe --stdin '$revset'"
fi

# Cleanup
rm -f "$tmpfile"

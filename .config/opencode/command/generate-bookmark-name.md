---
description: Generate a jj bookmark name from a jj diff
agent: build
model: github-copilot/grok-code-fast-1
---

Provide a jj bookmark name (a bookmark in jj is similar to a branch in Git). JJ bookmark names should follow Git branch names: a short type prefix (such as feature, fix, refactor, test, doc), followed by a concise, hyphenated description. Use '/' to separate type from description.

Diff:
!`jj diff --git --from $ARGUMENTS`

Output only the bookmark name. Do not include any other text.

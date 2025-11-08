---
description: Generate a description for a change using jj based on diff and recent commits
agent: build
model: github-copilot/grok-code-fast-1
---

Recent commits:
!`jj log -n 5`

Here is the diff for the specified revset:
!`jj diff --git --revision $ARGUMENTS`

Based on the diff and recent commits above, generate a description to use with `jj describe` — include a concise subject (max 72 characters) explaining the changes and motivations. Output **only** the description text.  

---
description: Generate a commit message from changes and recent commits
agent: build
model: github-copilot/grok-code-fast-1
---

Here are the recent commit logs:
!`git log --oneline -5`

Here is the diff of staged changes:
!`git diff --cached`

Based on the diff and the recent logs above, generate a **single** clear and concise commit message.
Output only the commit message, no extra commentary.

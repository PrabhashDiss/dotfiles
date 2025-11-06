---
description: Generate a PR title and body from changes
agent: build
model: github-copilot/grok-code-fast-1
---

Here is the diff between the base branch and current branch:
!`git diff develop...$ARGUMENTS`

Based on the diff, generate a PR title and body. Title format: '[ticket-id] type(scope): description' following Conventional Commit guidelines (types: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test). Body should summarize changes, purpose, and context.

Output the title on the first line, followed by a blank line, then the body. No extra commentary.
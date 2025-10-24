#!/usr/bin/env bash
set -euo pipefail

gwf() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "Not inside a git repository" >&2
        return 1
    fi

    local worktrees
    worktrees=$(git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2}')

    if [[ -z "$worktrees" ]]; then
        echo "No worktrees found" >&2
        return 1
    fi

    if ! command -v fzf >/dev/null 2>&1; then
        # Fallback: print list
        echo "$worktrees"
        return 0
    fi

    local selected
    selected=$(echo "$worktrees" | fzf --height=40% --reverse --border)
    if [[ -n "$selected" ]]; then
        cd "$selected" || return
    fi
}

gwr() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "Not inside a git repository" >&2
        return 1
    fi

    local current
    current=$(pwd -P)
    local toplevel
    if toplevel=$(git rev-parse --show-toplevel 2>/dev/null); then
        :
    else
        toplevel=""
    fi

    local worktrees
    worktrees=$(git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2}')

    local main_worktree
    if [[ -n "$toplevel" && $(echo "$worktrees" | grep -Fx "$toplevel") ]]; then
        main_worktree=$toplevel
    else
        main_worktree=$(echo "$worktrees" | head -n1)
    fi

    # Check if current is a tracked worktree and not the main one
    if [[ -n "$(echo "$worktrees" | grep -Fx "$current")" ]] && [[ "$current" != "$main_worktree" ]]; then
        # Check for uncommitted changes in the worktree
        if ! git diff --quiet || ! git diff --staged --quiet; then
            echo "There are uncommitted changes. Please commit or stash them before removing the worktree." >&2
            return 1
        fi
        echo "Removing worktree: $current"
        cd "$main_worktree" || return
        git worktree remove "$current"
    else
        echo "Not in a removable worktree (or it's the main worktree)" >&2
        return 1
    fi
}

gwc() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "Not inside a git repository" >&2
        return 1
    fi

    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$repo_root" ]]; then
        echo "Unable to determine repository root" >&2
        return 1
    fi

    local input
    read -r -p "Enter worktree name (<1>/<2>): " input
    if [[ -z "$input" || ! "$input" =~ / ]]; then
        echo "Invalid name. Expected format: <1>/<2>" >&2
        return 1
    fi

    local part1 part2 branch_name path_name target_path
    part1=${input%%/*}
    part2=${input#*/}
    branch_name="$part1/$part2"

    path_name="branches/${part1}-${part2}"
    target_path="$repo_root/$path_name"

    if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then
        git worktree add -b "$branch_name" "$target_path" HEAD
    else
        git worktree add "$target_path" "$branch_name"
    fi
    echo "Created worktree: $target_path (branch: $branch_name)"
}

case "${1:-}" in
    -f)
        gwf
        ;;
    -r)
        gwr
        ;;
    -c)
        gwc
        ;;
esac

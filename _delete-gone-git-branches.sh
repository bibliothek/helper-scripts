#!/bin/sh
# Prune remote-tracking refs, then delete local branches whose upstream is gone
set -eu

git fetch -p

git worktree prune

git branch -vv \
  | awk '/: gone\]/ {
      if ($1 == "*" || $1 == "+") branch = $2; else branch = $1
      path = ""
      if ($1 == "+" && match($0, / \([^)]*\) \[/)) path = substr($0, RSTART + 2, RLENGTH - 5)
      print branch "\t" path
    }' \
  | while IFS='	' read -r branch worktree; do
      if [ -n "$worktree" ]; then
        git worktree remove --force "$worktree"
        rm -rf "$worktree"
      fi
      git branch -D "$branch"
    done

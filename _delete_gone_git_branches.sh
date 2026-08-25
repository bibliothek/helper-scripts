#!/bin/sh
# Prune remote-tracking refs, then delete local branches whose upstream is gone
set -eu

git fetch -p

git branch -vv \
  | awk '/: gone\]/ { if ($1 == "*" || $1 == "+") print $2; else print $1 }' \
  | while IFS= read -r branch; do
      git branch -D "$branch"
    done

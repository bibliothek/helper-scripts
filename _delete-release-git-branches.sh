#!/bin/sh
# Delete all local branches under release/s*
set -eu

git branch --format='%(refname:short)' \
  | grep 'release/s' \
  | while IFS= read -r branch; do
      git branch -D "$branch"
    done

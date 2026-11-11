#!/bin/sh
# Create a git worktree on a new branch next to the current repo; see usage() below.
set -eu

usage() {
    cat <<'USAGE'
Create a worktree on a new branch in <repo-parent>/wt/<repo>-wt-<branch with / as ->
and print its path, so `cd "$(_new-worktree.sh <branch>)"` jumps into it.
Inside tmux, also open a new window there split into two side-by-side panes.

Usage: _new-worktree.sh <branch> [start-point]
USAGE
}

case "${1-}" in
    -h|--help)
        usage
        exit 0
        ;;
    '')
        echo "error: <branch> is required" >&2
        usage >&2
        exit 1
        ;;
esac

branch="$1"

# Main worktree, so this also works from inside another worktree.
root=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
dir="$(dirname "$root")/wt/$(basename "$root")-wt-$(printf '%s' "$branch" | tr / -)"

git -C "$root" worktree add -b "$branch" "$dir" ${2:+"$2"} >&2

if [ -n "${TMUX-}" ]; then
    win=$(tmux new-window -P -F '#{window_id}' -c "$dir")
    tmux split-window -h -t "$win" -c "$dir"
    tmux select-pane -t "$win" -L
fi

echo "$dir"

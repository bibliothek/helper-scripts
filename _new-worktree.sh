#!/bin/sh
# Create a git worktree on a new branch next to the current repo; see usage() below.
set -eu

usage() {
    cat <<'USAGE'
Create a worktree on a new branch in <repo-parent>/wt/<repo>-wt-<branch with / as ->
and print its path, so `cd "$(_new-worktree.sh <branch>)"` jumps into it.
Inside tmux, also open a new window there.

Usage: _new-worktree.sh [-C <repo-path>] <branch>

  -C, --directory <repo-path>  use the repo at <repo-path> instead of the current one
USAGE
}

repo=.
while :; do
    case "${1-}" in
        -h|--help)
            usage
            exit 0
            ;;
        -C|--directory)
            [ $# -ge 2 ] || { echo "error: $1 requires a path" >&2; exit 1; }
            repo="$2"
            shift 2
            ;;
        '')
            echo "error: <branch> is required" >&2
            usage >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

branch="$1"

# Main worktree, so this also works from inside another worktree.
root=$(dirname "$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir)")
dir="$(dirname "$root")/wt/$(basename "$root")-wt-$(printf '%s' "$branch" | tr / -)"

git -C "$root" worktree add -b "$branch" "$dir" >&2

if [ -n "${TMUX-}" ]; then
    tmux new-window -c "$dir"
fi

echo "$dir"

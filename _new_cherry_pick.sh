#!/bin/sh
# Cherry-pick one commit onto a target branch and open a PR for it; see usage() below.
set -eu

usage() {
    cat <<'USAGE'
Cherry-pick a commit onto <target-branch> on a new cp/ branch and open a PR for it.

Usage: _new_cherry_pick.sh <target-branch> (-b | -p <pr-number> [-c <hash>])

  -b, --use-branch      cherry-pick HEAD of the current branch, resolving its PR number
  -p, --pr <number>     cherry-pick from this PR (its first commit unless -c is given)
  -c, --hash <hash>     commit to cherry-pick (only with -p)

Afterwards the clipboard holds:
  👀 <commit message>
  🌸 <original PR url>
  🍒 <cherry-pick PR url>
An existing 👀 block in the clipboard is kept and only appended to.
USAGE
}

target_branch=''
use_branch=0
pr_number=''
hash=''

while [ $# -gt 0 ]; do
    case "$1" in
        -b|--use-branch)
            use_branch=1
            ;;
        -p|--pr)
            shift
            pr_number="${1-}"
            ;;
        -c|--hash)
            shift
            hash="${1-}"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            target_branch="${1-}"
            break
            ;;
        -*)
            echo "unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            target_branch="$1"
            ;;
    esac
    shift
done

if [ -z "$target_branch" ]; then
    echo "error: <target-branch> is required" >&2
    usage >&2
    exit 1
fi

if [ "$use_branch" -eq 0 ] && [ -z "$pr_number" ]; then
    echo "error: specify a PR number with -p, or use -b to cherry-pick the current branch" >&2
    usage >&2
    exit 1
fi

if [ "$use_branch" -eq 1 ] && { [ -n "$pr_number" ] || [ -n "$hash" ]; }; then
    echo "error: -b cannot be combined with -p or -c" >&2
    usage >&2
    exit 1
fi

if [ "$use_branch" -eq 1 ]; then
    hash=$(git rev-parse HEAD)
    branch_name=$(git rev-parse --abbrev-ref HEAD)
    pr_number=$(gh pr view "$branch_name" --json number --jq .number)
else
    branch_name=$(gh pr view "$pr_number" --json headRefName --jq .headRefName)
    if [ -z "$hash" ]; then
        hash=$(gh pr view "$pr_number" --json commits --jq '.commits[0].oid')
    fi
fi

# Collapse a multi-line message to one line so it works as a PR title.
commit_message=$(git log -1 --pretty=%B "$hash" -- | tr '\n' ' ' | sed 's/ *$//')

cp_branch="cp/$target_branch/$branch_name"

git checkout "$target_branch"
git pull
git checkout -b "$cp_branch"

git cherry-pick "$hash"

git push --set-upstream origin "$cp_branch"

gh pr create \
    --base "$target_branch" \
    --body "cherry-pick from #$pr_number" \
    --title "🍒 $commit_message" \
    --assignee "@me"

clipboard=$(pbpaste)
case "$clipboard" in
    👀*)
        ;;
    *)
        original_pr_url=$(gh pr view "$pr_number" --json url --jq '.url')
        clipboard=$(printf '👀 %s\n🌸 %s' "$commit_message" "$original_pr_url")
        ;;
esac

pr_url=$(gh pr view --json url --jq '.url')

printf '%s\n🍒 %s\n' "$clipboard" "$pr_url" | pbcopy

#!/bin/sh
# Create a GitHub PR for the current branch; see usage() below.
set -eu

usage() {
    cat <<'USAGE'
Create a GitHub PR for the current branch and copy "👀 <title> <url>" to the clipboard.

Usage: _new_pr.sh [-a|--add-and-commit] <commit-message>
  -a, --add-and-commit  stage everything and commit with <commit-message> first
USAGE
}

add_and_commit=0
commit_message=''

while [ $# -gt 0 ]; do
    case "$1" in
        -a|--add-and-commit)
            add_and_commit=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            commit_message="${1-}"
            break
            ;;
        -*)
            echo "unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            commit_message="$1"
            ;;
    esac
    shift
done

if [ -z "$commit_message" ]; then
    echo "error: <commit-message> is required" >&2
    usage >&2
    exit 1
fi

if [ "$add_and_commit" -eq 1 ]; then
    git add .
    git commit -m "$commit_message"
fi

git push --set-upstream origin "$(git symbolic-ref --quiet --short HEAD)"

gh pr create \
    -b "$(printf '## Description \n\n%s\n' "$commit_message")" \
    -t "$commit_message" \
    --assignee=@me

pr_url=$(gh pr view --json url --jq '.url')

printf '👀 %s\n%s\n' "$commit_message" "$pr_url" | pbcopy

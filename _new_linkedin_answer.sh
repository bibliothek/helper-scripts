#!/bin/sh
# Copy a polite "not looking" LinkedIn reply to the clipboard; see usage() below.
set -eu

usage() {
    cat <<'USAGE'
Copy a polite "not looking for something new" LinkedIn reply to the clipboard.

Usage: _new_linkedin_answer.sh <name> [DE|EN]
       _new_linkedin_answer.sh <name> [-l|--language DE|EN]

Language defaults to DE.
USAGE
}

name=''
language='DE'

while [ $# -gt 0 ]; do
    case "$1" in
        -l|--language)
            shift
            language="${1-}"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            continue
            ;;
        -*)
            echo "unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            if [ -z "$name" ]; then
                name="$1"
            else
                language="$1"
            fi
            ;;
    esac
    shift
done

if [ -z "$name" ]; then
    echo "error: <name> is required" >&2
    usage >&2
    exit 1
fi

case "$language" in
    DE|de)
        response=$(printf 'Hallo %s,\n\nich bin happy in meiner aktuellen Position und nicht auf der Suche nach etwas Neuem.\n\nLG' "$name")
        ;;
    EN|en)
        response=$(printf "Hi %s,\n\nI'm happy in my current position and not looking for something new.\n\nBR" "$name")
        ;;
    *)
        echo "error: language must be DE or EN (got: $language)" >&2
        exit 1
        ;;
esac

printf '%s' "$response" | pbcopy
echo "Copied to clipboard"

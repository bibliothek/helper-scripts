#!/bin/sh
# Create German-labelled daily-note markdown files; see usage() below.
set -eu

usage() {
    cat <<'USAGE'
Create daily-note files under <root>/<year>/<month>/0_YYYY-MM-DD-<Wochentag>.md

Usage: _new_daily_note.sh [options]

  (no options)             create today's note
  -y, --year <yyyy>        create notes for that whole year (Jan 1 - Dec 31)
  -r, --root-path <path>   notes root (default: ~/notes/dailynote)
  -h, --help               show this help

Each created file's path is printed. Content is appended, so re-running on an
existing note adds a second header block.
USAGE
}

root_path="$HOME/notes/dailynote"
year=''

while [ $# -gt 0 ]; do
    case "$1" in
        -r|--root-path)  shift; root_path="${1-}" ;;
        -y|--year)       shift; year="${1-}" ;;
        -h|--help)       usage; exit 0 ;;
        --)              shift; continue ;;
        *)
            echo "unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

case "$root_path" in
    '~') root_path="$HOME" ;;
    '~/'*) root_path="$HOME/${root_path#\~/}" ;;
esac

# BSD (macOS) and GNU date take completely different flags; pick once.
if date -j '+%Y' >/dev/null 2>&1; then
    date_flavor=bsd
else
    date_flavor=gnu
fi

# date_at <YYYY-MM-DD> <day-offset> <strftime-format>
date_at() {
    _d=$1
    _n=$2
    _f=$3
    case "$_n" in
        -*) _sign='' ;;
        *)  _sign='+' ;;
    esac
    if [ "$date_flavor" = bsd ]; then
        date -j -v"${_sign}${_n}d" -f '%Y-%m-%d' "$_d" "+$_f"
    else
        date -d "$_d ${_sign}${_n} days" "+$_f"
    fi
}

# Reject anything that is not a real, canonically written YYYY-MM-DD date --
# BSD date happily rolls 2026-02-30 over into March instead of failing.
require_date() {
    if [ "$(date_at "$1" 0 '%Y-%m-%d' 2>/dev/null)" != "$1" ]; then
        echo "error: not a valid YYYY-MM-DD date: $1" >&2
        exit 1
    fi
}

weekday_de() {
    case "$(date_at "$1" 0 '%u')" in
        1) echo Montag ;;
        2) echo Dienstag ;;
        3) echo Mittwoch ;;
        4) echo Donnerstag ;;
        5) echo Freitag ;;
        6) echo Samstag ;;
        7) echo Sonntag ;;
    esac
}

as_number() { echo "$1" | tr -d -; }

create_file() {
    _date=$1
    _year=$(date_at "$_date" 0 '%Y')
    _month=$(date_at "$_date" 0 '%m')
    _month=${_month#0}
    _folder="$root_path/0_$_year/0_$_month"

    [ -d "$_folder" ] || mkdir -p "$_folder"

    _weekday=$(weekday_de "$_date")
    _file="$_folder/0_${_date}-${_weekday}.md"

    echo "$_file"

    printf '# %s-%s\n\n#dailynote #y%s\n\n---\n\n\n' \
        "$_date" "$_weekday" "$_year" >> "$_file"
}

# create_files <start-inclusive> <end-exclusive>
create_files() {
    _cur=$1
    _end_num=$(as_number "$2")
    while [ "$(as_number "$_cur")" -lt "$_end_num" ]; do
        create_file "$_cur"
        _cur=$(date_at "$_cur" 1 '%Y-%m-%d')
    done
}

today=$(date '+%Y-%m-%d')

if [ -n "$year" ]; then
    case "$year" in
        ''|*[!0-9]*) echo "error: -y must be a 4-digit year (got: $year)" >&2; exit 1 ;;
    esac
    if [ "${#year}" -ne 4 ]; then
        echo "error: -y must be a 4-digit year (got: $year)" >&2
        exit 1
    fi

    start="$year-01-01"
    require_date "$start"
    create_files "$start" "$((year + 1))-01-01"
else
    create_file "$today"
fi

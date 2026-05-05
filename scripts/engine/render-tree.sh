#!/usr/bin/env bash
# Templatizer theme rendering engine: copy a file tree and substitute __TOKENS__.
# Usage: render-tree.sh <source_root> <destination_root>
# Required environment (export before calling):
#   APP_NAME, APP_NAME_LOWER, APP_NAME_CLASS
# Optional:
#   APP_DISPLAY_NAME (defaults to APP_NAME)
#
# Placeholders in source files (UTF-8 text):
#   __APP_NAME__          — PascalCase / human app name from CLI
#   __APP_NAME_LOWER__    — directory slug
#   __APP_NAME_CLASS__    — module-style class prefix if needed
#   __APP_DISPLAY_NAME__  — short product name shown in UI (defaults to APP_NAME)

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <source_root> <destination_root>" >&2
  exit 1
fi

SRC="$(cd "$1" && pwd)"
DST="$(cd "$2" && pwd)"

if [ ! -d "$SRC" ]; then
  echo "Source not a directory: $SRC" >&2
  exit 1
fi

if [ ! -d "$DST" ]; then
  echo "Destination not a directory: $DST" >&2
  exit 1
fi

: "${APP_NAME:?APP_NAME is required}"
: "${APP_NAME_LOWER:?APP_NAME_LOWER is required}"
: "${APP_NAME_CLASS:?APP_NAME_CLASS is required}"

DISPLAY="${APP_DISPLAY_NAME:-$APP_NAME}"

export LC_ALL=C

while IFS= read -r -d '' f; do
  rel="${f#"$SRC"/}"
  [ -z "$rel" ] && continue
  out="$DST/$rel"
  mkdir -p "$(dirname "$out")"
  sed \
    -e "s/__APP_NAME__/${APP_NAME//\//\\/}/g" \
    -e "s/__APP_NAME_LOWER__/${APP_NAME_LOWER//\//\\/}/g" \
    -e "s/__APP_NAME_CLASS__/${APP_NAME_CLASS//\//\\/}/g" \
    -e "s/__APP_DISPLAY_NAME__/${DISPLAY//\//\\/}/g" \
    "$f" > "$out"
done < <(find "$SRC" -type f -print0)

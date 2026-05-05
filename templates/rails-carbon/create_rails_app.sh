#!/usr/bin/env bash
# Rails Carbon edition — IBM Carbon-aligned UI; file-driven theme via render-tree engine.
set -e
export TEMPLATIZER_THEME=carbon
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.shared/create_rails_app.sh" "$@"

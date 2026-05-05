#!/usr/bin/env bash
# Rails Modern edition — delegates to shared generator with the default UI theme.
set -e
export TEMPLATIZER_THEME="${TEMPLATIZER_THEME:-modern}"
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.shared/create_rails_app.sh" "$@"

#!/usr/bin/env bash
# The WezTerm config tests, run inside WezTerm's own Lua. Run: bash test-wezterm.sh
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v wezterm >/dev/null; then
  echo "skipped: wezterm not installed"
  exit 0
fi

# A broken run.lua makes WezTerm load its defaults and exit 0, so a pass
# also needs the runner's own summary line.
status=0
output="$(wezterm --config-file "$TESTS_DIR/run.lua" show-keys 2>&1 >/dev/null)" || status=$?
grep -v '^$' <<<"$output" || true

if [[ "$status" != 0 || "$output" != *"wezterm tests: "*" 0 failed"* ]]; then
  echo "FAIL  wezterm tests (exit $status)"
  exit 1
fi

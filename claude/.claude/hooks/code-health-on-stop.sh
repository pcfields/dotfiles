#!/usr/bin/env bash
# Stop hook. When Claude finishes a turn, runs `code-health safeguard` and, if
# a changed file gained or worsened a code smell, sends the report back so
# Claude keeps working. The logic lives in the harness-neutral code-health
# CLI; this file only translates Claude's event into a call to it.
#
# Fails open like run-check-on-stop.sh: a missing or broken tool warns and
# lets Claude stop. CODE_HEALTH_CMD overrides the command to run.
set -euo pipefail

input="$(cat)"

# Claude is already continuing because a Stop hook blocked once. Let it stop,
# so a finding that has to stay can't loop.
if [[ "$(jq -r '.stop_hook_active // false' <<<"$input" 2>/dev/null)" == "true" ]]; then
  exit 0
fi

cwd="$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)" || cwd=""
cd "${cwd:-.}" 2>/dev/null || exit 0
git rev-parse --show-toplevel >/dev/null 2>&1 || exit 0
[[ -n "$(git status --porcelain)" ]] || exit 0

skip() {
  echo "code-health-on-stop: skipped, $1" >&2
  exit 0
}

tool="$HOME/.agents/tools/code-health"
if [[ -n "${CODE_HEALTH_CMD:-}" ]]; then
  read -ra cmd <<<"$CODE_HEALTH_CMD"
elif command -v code-health >/dev/null; then
  cmd=(code-health)
elif command -v uv >/dev/null && [[ -d "$tool" ]]; then
  # Until `uv tool install` puts code-health on PATH (plan step 11).
  cmd=(uv run --quiet --locked --project "$tool" code-health)
else
  skip "code-health is not installed"
fi

status=0
output="$("${cmd[@]}" safeguard 2>&1)" || status=$?
case "$status" in
  0) exit 0 ;;
  2)
    printf '%s\n' "$output" >&2
    exit 2
    ;;
  *) skip "code-health failed (exit $status): $(tail -n 3 <<<"$output")" ;;
esac

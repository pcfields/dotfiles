#!/usr/bin/env bash
# Stop hook. When Claude finishes a turn, runs `code-health safeguard` on
# everything since the turn started (see code-health-turn-start.sh), and, if
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
session="$(jq -r '.session_id // "default"' <<<"$input" 2>/dev/null)" || session=default
cd "${cwd:-.}" 2>/dev/null || exit 0
git rev-parse --show-toplevel >/dev/null 2>&1 || exit 0

skip() {
  echo "code-health-on-stop: skipped, $1" >&2
  exit 0
}

# shellcheck source=code-health-command.sh
source "$(dirname "${BASH_SOURCE[0]}")/code-health-command.sh"
code_health_command || skip "code-health is not installed"

status=0
output="$("${cmd[@]}" safeguard --since-turn --session "$session" 2>&1)" || status=$?
case "$status" in
  0) exit 0 ;;
  2)
    printf '%s\n' "$output" >&2
    exit 2
    ;;
  *) skip "code-health failed (exit $status): $(tail -n 3 <<<"$output")" ;;
esac

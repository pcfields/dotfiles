#!/usr/bin/env bash
# Stop hook. When Claude finishes a turn, runs `code-health safeguard` on
# everything since the turn started (see code-health-turn-start.sh), and, if
# a changed file gained or worsened a code smell, sends the report back so
# Claude keeps working. It also records the refactoring episode: a failure
# opens one, the fix closes it, and the transcript gives its token cost.
# The logic lives in the harness-neutral code-health CLI; this file only
# translates Claude's event into calls to it.
#
# Fails open like run-check-on-stop.sh: a missing or broken tool warns and
# lets Claude stop. CODE_HEALTH_CMD overrides the command to run.
set -euo pipefail

input="$(cat)"
cwd="$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)" || cwd=""
session="$(jq -r '.session_id // "default"' <<<"$input" 2>/dev/null)" || session=default
transcript="$(jq -r '.transcript_path // empty' <<<"$input" 2>/dev/null)" || transcript=""
active="$(jq -r '.stop_hook_active // false' <<<"$input" 2>/dev/null)" || active=false
cd "${cwd:-.}" 2>/dev/null || exit 0
git rev-parse --show-toplevel >/dev/null 2>&1 || exit 0

skip() {
  echo "code-health-on-stop: skipped, $1" >&2
  exit 0
}

# shellcheck source=code-health-command.sh
source "$(dirname "${BASH_SOURCE[0]}")/code-health-command.sh"
code_health_command || skip "code-health is not installed"
tokens=()
[[ -n "$transcript" ]] && tokens=(--transcript "$transcript")

# Claude is already continuing because a Stop hook blocked once. Close the
# episode, pass or fail, and let it stop, so a finding that has to stay
# can't loop.
if [[ "$active" == "true" ]]; then
  "${cmd[@]}" episode end --kind safeguard-fix --session "$session" >/dev/null 2>&1 || true
  "${cmd[@]}" episode flush --session "$session" "${tokens[@]}" >/dev/null 2>&1 || true
  exit 0
fi

status=0
output="$("${cmd[@]}" safeguard --since-turn --session "$session" --episode "${tokens[@]}" 2>&1)" || status=$?
case "$status" in
  0) exit 0 ;;
  2)
    printf '%s\n' "$output" >&2
    exit 2
    ;;
  *) skip "code-health failed (exit $status): $(tail -n 3 <<<"$output")" ;;
esac

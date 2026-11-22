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

# shellcheck source=code-health-command.sh
source "$(dirname "${BASH_SOURCE[0]}")/code-health-command.sh"

main() {
  local input
  input="$(cat)"
  field cwd "$input" "" && cd "${value:-.}" 2>/dev/null || exit 0
  git rev-parse --show-toplevel >/dev/null 2>&1 || exit 0
  field session_id "$input" default && session="$value"
  field transcript_path "$input" "" && tokens=()
  [[ -z "$value" ]] || tokens=(--transcript "$value")
  code_health_command || skip "code-health is not installed"

  field stop_hook_active "$input" false
  if [[ "$value" == "true" ]]; then
    close_episode
  fi
  run_safeguard
}

# field <name> <json> <default>: sets `value` to the event's field, or the default.
field() {
  value="$(jq -r --arg d "$3" ".$1 // \$d" <<<"$2" 2>/dev/null)" || value="$3"
}

# Claude is already continuing because a Stop hook blocked once. Close the
# episode, pass or fail, and let it stop, so a finding that has to stay
# can't loop.
close_episode() {
  "${cmd[@]}" episode end --kind safeguard-fix --session "$session" >/dev/null 2>&1 || true
  "${cmd[@]}" episode flush --session "$session" "${tokens[@]}" >/dev/null 2>&1 || true
  exit 0
}

run_safeguard() {
  local status=0 output
  output="$("${cmd[@]}" safeguard --since-turn --session "$session" --episode "${tokens[@]}" 2>&1)" || status=$?
  case "$status" in
    0) exit 0 ;;
    2)
      printf '%s\n' "$output" >&2
      exit 2
      ;;
    *) skip "code-health failed (exit $status): $(tail -n 3 <<<"$output")" ;;
  esac
}

skip() {
  echo "code-health-on-stop: skipped, $1" >&2
  exit 0
}

main

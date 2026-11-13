#!/usr/bin/env bash
# Stop hook. When Claude finishes a turn, runs the project's `check` command
# and, if it fails, sends the output back so Claude keeps working. The logic
# lives in the harness-neutral ~/.agents/checks/run-project-check.sh; this
# file only translates Claude's event into a call to it.
#
# Unlike the PreToolUse guards this fails open: a broken hook must not trap
# the session.
set -euo pipefail

input="$(cat)"

# Claude is already continuing because this hook blocked once. Let it stop
# now, so a check that can't pass doesn't loop.
if [[ "$(jq -r '.stop_hook_active // false' <<<"$input" 2>/dev/null)" == "true" ]]; then
  exit 0
fi

cwd="$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)" || cwd=""
exec bash "$HOME/.agents/checks/run-project-check.sh" "${cwd:-.}"

#!/usr/bin/env bash
# UserPromptSubmit hook. Records HEAD as the start of Claude's turn, so the
# Stop hook's `code-health safeguard --since-turn` also checks work Claude
# commits during the turn. Never blocks the prompt.
set -euo pipefail

input="$(cat)"
cwd="$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)" || cwd=""
session="$(jq -r '.session_id // "default"' <<<"$input" 2>/dev/null)" || session=default
cd "${cwd:-.}" 2>/dev/null || exit 0
git rev-parse --show-toplevel >/dev/null 2>&1 || exit 0

# shellcheck source=code-health-command.sh
source "$(dirname "${BASH_SOURCE[0]}")/code-health-command.sh"
code_health_command || exit 0
"${cmd[@]}" mark-turn --session "$session" >/dev/null 2>&1 || true
exit 0

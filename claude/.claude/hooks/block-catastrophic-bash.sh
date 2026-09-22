#!/usr/bin/env bash
# PreToolUse hook for Bash. Blocks a narrow deny-list of catastrophic
# commands. Defense in depth only - the sandbox and permission prompts are the
# real boundary. Keep the list short to avoid false positives.
set -euo pipefail

input="$(cat)"
if ! command="$(jq -er '.tool_input.command // ""' <<<"$input" 2>/dev/null)"; then
  echo "Blocked: hook input was not valid JSON." >&2
  exit 2
fi

[[ -z "$command" ]] && exit 0

if grep -qE '(^|[[:space:];&|("'\''])rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*)[[:space:]]+(/[[:space:]]*($|[;&|)"'\''])|/\*|~/?[[:space:]]*($|[;&|)"'\''])|~/\*|\$HOME/?[[:space:]]*($|[;&|)"'\'']))' <<<"$command"; then
  echo "Blocked: this command looks like it recursively force-deletes a home or root path." >&2
  exit 2
fi

if grep -qE '(^|[[:space:];&|("'\''])(mkfs|dd[[:space:]]+.*of=/dev/)' <<<"$command"; then
  echo "Blocked: this command looks like a destructive disk-level operation." >&2
  exit 2
fi

if grep -qE 'chmod[[:space:]]+(-R|--recursive)[[:space:]]+777[[:space:]]+/([[:space:]]|$)' <<<"$command"; then
  echo "Blocked: this command recursively opens permissions on /." >&2
  exit 2
fi

if grep -qE '(^|[[:space:];&|("'\''])git[[:space:]]+push([[:space:]]|$)' <<<"$command" \
  && grep -qE '(^|[[:space:]])(--force(-with-lease)?([[:space:]]|=|$)|-f([[:space:]]|$))|[[:space:]]\+[^[:space:]]' <<<"$command" \
  && grep -qE '(^|[[:space:]/:+])(main|master)([[:space:]"'\'')]|$)' <<<"$command"; then
  echo "Blocked: this command force-pushes to main/master. Confirm with the user first." >&2
  exit 2
fi

exit 0

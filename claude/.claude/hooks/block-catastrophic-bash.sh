#!/usr/bin/env bash
# PreToolUse hook for Bash. Blocks a narrow deny-list of catastrophic
# commands. This is a belt-and-suspenders safety net, not a substitute for
# normal permission prompts - keep the list short to avoid false positives.
set -euo pipefail

input="$(cat)"
command="$(echo "$input" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*:[[:space:]]*"(.*)"/\1/')"

[[ -z "$command" ]] && exit 0

if echo "$command" | grep -qE '(^|[[:space:];&|])rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*)[[:space:]]+(/[[:space:]]*$|/\*|~[[:space:]]*$|~/\*|\$HOME[[:space:]]*$)'; then
  echo "Blocked: '$command' looks like it recursively force-deletes a home or root path." >&2
  exit 2
fi

if echo "$command" | grep -qE '(^|[[:space:];&|])(mkfs|dd[[:space:]]+.*of=/dev/)'; then
  echo "Blocked: '$command' looks like a destructive disk-level operation." >&2
  exit 2
fi

if echo "$command" | grep -qE 'chmod[[:space:]]+(-R|--recursive)[[:space:]]+777[[:space:]]+/([[:space:]]|$)'; then
  echo "Blocked: '$command' recursively opens permissions on /." >&2
  exit 2
fi

if echo "$command" | grep -qE '(^|[[:space:];&|])git[[:space:]]+push([[:space:]]|$)' \
  && echo "$command" | grep -qE '(^|[[:space:]])(--force(-with-lease)?([[:space:]]|=|$)|-f([[:space:]]|$))' \
  && echo "$command" | grep -qE '(^|[[:space:]/:])(main|master)([[:space:]]|$)'; then
  echo "Blocked: '$command' force-pushes to main/master. Confirm with the user first." >&2
  exit 2
fi

exit 0

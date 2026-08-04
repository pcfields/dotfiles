#!/usr/bin/env bash
# PreToolUse hook for Edit|Write. Blocks writes to secret-shaped paths.
# No jq dependency assumed - extract file_path with grep/sed since it's a
# single flat JSON field on stdin.
set -euo pipefail

input="$(cat)"
file_path="$(echo "$input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*:[[:space:]]*"(.*)"/\1/')"

[[ -z "$file_path" ]] && exit 0

shopt -s nocasematch
case "$file_path" in
  *.env|*.env.*|*/.env|*/.env.*|*.pem|*id_rsa*|*id_ed25519*|*credentials*|*/.ssh/*|*.pfx|*.p12)
    echo "Blocked: '$file_path' looks like a secret/credential file. Edit it manually if this is intentional." >&2
    exit 2
    ;;
esac

exit 0

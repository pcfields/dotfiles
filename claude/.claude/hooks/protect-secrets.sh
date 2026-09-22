#!/usr/bin/env bash
# PreToolUse hook for Read|Edit|Write. Blocks access to secret-shaped paths so
# their contents never enter the conversation. Backs up the Read deny rules in
# settings.json, which only cover the Read tool's own path matching.
set -euo pipefail

input="$(cat)"
if ! file_path="$(jq -er '.tool_input.file_path // ""' <<<"$input" 2>/dev/null)"; then
  echo "Blocked: hook input was not valid JSON." >&2
  exit 2
fi

[[ -z "$file_path" ]] && exit 0

# Normalise Windows separators so one pattern list covers both platforms.
file_path="${file_path//\\//}"

shopt -s nocasematch
case "$file_path" in
  */.env.example|*/.env.sample|*/.env.template) exit 0 ;;
  .env|.env.*|*/.env|*/.env.*|*.pem|*.key|*.pfx|*.p12|*/id_rsa*|*/id_ed25519*|*/id_ecdsa*|*/.ssh/*|*/.aws/credentials|*/.config/gh/hosts.yml|*/.claude/.credentials.json)
    echo "Blocked: '$file_path' looks like a secret/credential file. Handle it manually if this is intentional." >&2
    exit 2
    ;;
esac

exit 0

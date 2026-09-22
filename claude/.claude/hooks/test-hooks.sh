#!/usr/bin/env bash
# Regression fixtures for the PreToolUse hooks. Run: bash test-hooks.sh
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failures=0

# expect <want-exit> <hook> <raw-json-input> <label>
expect() {
  local want="$1" hook="$2" input="$3" label="$4" got=0
  printf '%s' "$input" | bash "$HOOK_DIR/$hook" >/dev/null 2>&1 || got=$?
  if [[ "$got" == "$want" ]]; then
    printf 'ok    %s\n' "$label"
  else
    printf 'FAIL  %s (want %s, got %s)\n' "$label" "$want" "$got"
    failures=$((failures + 1))
  fi
}

bash_cmd() { jq -cn --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}'; }
file_op() { jq -cn --arg p "$1" '{tool_name:"Read",tool_input:{file_path:$p}}'; }

B=block-catastrophic-bash.sh
expect 2 "$B" "$(bash_cmd 'rm -rf /')" "rm -rf /"
expect 2 "$B" "$(bash_cmd 'rm -fr ~')" "rm -fr ~"
expect 2 "$B" "$(bash_cmd 'rm -rf $HOME')" "rm -rf \$HOME"
expect 2 "$B" "$(bash_cmd 'bash -c "rm -rf /"')" "wrapped in bash -c with escaped quotes"
expect 2 "$B" "$(bash_cmd 'cd /tmp && rm -rf /*')" "compound command"
expect 2 "$B" "$(bash_cmd 'sudo mkfs.ext4 /dev/sda1')" "mkfs"
expect 2 "$B" "$(bash_cmd 'dd if=/dev/zero of=/dev/sda')" "dd to device"
expect 2 "$B" "$(bash_cmd 'git push --force origin main')" "force push main"
expect 2 "$B" "$(bash_cmd 'git push -f origin master')" "force push master (-f)"
expect 2 "$B" "$(bash_cmd 'git push origin +main')" "force refspec +main"
expect 2 "$B" 'not json' "malformed input fails closed"
expect 0 "$B" "$(bash_cmd 'rm -rf ./build')" "rm -rf relative dir"
expect 0 "$B" "$(bash_cmd 'rm -rf /tmp/foo')" "rm -rf absolute subdir"
expect 0 "$B" "$(bash_cmd 'git push origin main')" "normal push main"
expect 0 "$B" "$(bash_cmd 'git push --force origin feature/x')" "force push feature branch"
expect 0 "$B" '{"tool_input":{}}' "missing command"

S=protect-secrets.sh
expect 2 "$S" "$(file_op '/repo/.env')" ".env"
expect 2 "$S" "$(file_op '/repo/.env.local')" ".env.local"
expect 2 "$S" "$(file_op '/home/u/.ssh/config')" "~/.ssh/config"
expect 2 "$S" "$(file_op '/home/u/.aws/credentials')" "aws credentials"
expect 2 "$S" "$(file_op 'C:\Users\u\.ssh\id_ed25519')" "windows ssh key"
expect 2 "$S" "$(file_op '/certs/server.pem')" "pem"
expect 2 "$S" 'not json' "malformed input fails closed"
expect 0 "$S" "$(file_op '/repo/.env.example')" ".env.example allowed"
expect 0 "$S" "$(file_op '/repo/src/auth/credentials.ts')" "credentials.ts source allowed"
expect 0 "$S" "$(file_op '/repo/README.md')" "ordinary file"

echo
if ((failures)); then
  echo "$failures failure(s)"
  exit 1
fi
echo "all passed"

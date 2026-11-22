#!/usr/bin/env bash
# Regression fixtures for the PreToolUse and Stop hooks. Run: bash test-hooks.sh
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failures=0

# expect <want-exit> <hook> <raw-json-input> <label> [<text expected on stderr>]
expect() {
  local want="$1" hook="$2" input="$3" label="$4" text="${5:-}" got=0 stderr
  stderr="$(printf '%s' "$input" | bash "$HOOK_DIR/$hook" 2>&1 >/dev/null)" || got=$?
  if [[ "$got" != "$want" ]]; then
    printf 'FAIL  %s (want %s, got %s)\n' "$label" "$want" "$got"
    failures=$((failures + 1))
  elif [[ -n "$text" && "$stderr" != *"$text"* ]]; then
    printf 'FAIL  %s (stderr lacks "%s")\n' "$label" "$text"
    failures=$((failures + 1))
  else
    printf 'ok    %s\n' "$label"
  fi
}

bash_cmd() { jq -cn --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}'; }
pwsh_cmd() { jq -cn --arg c "$1" '{tool_name:"PowerShell",tool_input:{command:$c}}'; }
file_op() { jq -cn --arg p "$1" '{tool_name:"Read",tool_input:{file_path:$p}}'; }
grep_op() { jq -cn --arg p "$1" '{tool_name:"Grep",tool_input:{pattern:"KEY",path:$p}}'; }

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
expect 2 "$B" "$(pwsh_cmd 'git push --force origin main')" "PowerShell force push main"
expect 0 "$B" "$(pwsh_cmd 'git push origin main')" "PowerShell normal push"

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
expect 2 "$S" "$(grep_op '/repo/.env')" "grep inside .env"
expect 2 "$S" "$(grep_op '/home/u/.ssh')" "grep the .ssh dir"
expect 0 "$S" "$(grep_op '/repo/src')" "grep ordinary dir"
expect 0 "$S" '{"tool_name":"Grep","tool_input":{"pattern":"x"}}' "grep with no path"

# Stop hook: a throwaway repo with uncommitted changes and a failing check.
C=run-check-on-stop.sh
repo="$(mktemp -d)"
trap "rm -rf '$repo'" EXIT
git -C "$repo" init -q
mkdir "$repo/.agents" && echo 'exit 1' >"$repo/.agents/check"
stop_event() { jq -cn --arg d "$repo" --argjson active "$1" '{hook_event_name:"Stop",cwd:$d,stop_hook_active:$active}'; }
expect 2 "$C" "$(stop_event false)" "stop: failing check sends Claude back"
expect 0 "$C" "$(stop_event true)" "stop: second stop is let through"
expect 0 "$C" "$(jq -cn --arg d "$repo/missing" '{cwd:$d}')" "stop: unknown directory fails open"
echo 'exit 0' >"$repo/.agents/check"
expect 0 "$C" "$(stop_event false)" "stop: passing check lets Claude stop"

# Code-health Stop hook: the real tool on a throwaway repo.
H=code-health-on-stop.sh
health="$(mktemp -d)"
trap "rm -rf '$repo' '$health'" EXIT
health_git() { git -C "$health" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false "$@"; }
health_event() { jq -cn --arg d "$health" --argjson active "$1" '{hook_event_name:"Stop",cwd:$d,stop_hook_active:$active}'; }
health_git init -q
printf 'export function f(a) {\n  return a;\n}\n' >"$health/app.ts"
health_git add -A && health_git commit -q -m init
expect 0 "$H" "$(health_event false)" "code-health: clean tree lets Claude stop"
printf 'export function f(a) {\n  return a + 1;\n}\n' >"$health/app.ts"
expect 0 "$H" "$(health_event false)" "code-health: change with no new findings lets Claude stop"
printf 'export function f(a) {\n  if (a) { if (a.b) { if (a.c) { if (a.d) { return 1; } } } }\n  return 0;\n}\n' >"$health/app.ts"
expect 2 "$H" "$(health_event false)" "code-health: new finding sends Claude back" "x new"
expect 0 "$H" "$(health_event true)" "code-health: second stop is let through"
expect 0 "$H" "$(jq -cn --arg d "$health/missing" '{cwd:$d}')" "code-health: unknown directory fails open"
expect 0 "$H" "$(jq -cn --arg d "$(dirname "$health")" '{cwd:$d}')" "code-health: not a git repo is skipped"
export CODE_HEALTH_CMD="$health/no-such-command"
expect 0 "$H" "$(health_event false)" "code-health: missing tool fails open" "code-health-on-stop: skipped"
export CODE_HEALTH_CMD=false
expect 0 "$H" "$(health_event false)" "code-health: tool error fails open" "code-health-on-stop: skipped"
unset CODE_HEALTH_CMD

# Turn base: a regression committed during the turn is still caught.
T=code-health-turn-start.sh
health_state="$(mktemp -d)"
trap "rm -rf '$repo' '$health' '$health_state'" EXIT
export CODE_HEALTH_STATE_DIR="$health_state"
turn_event() { jq -cn --arg d "$health" --arg e "$1" '{hook_event_name:$e,cwd:$d,session_id:"t1",stop_hook_active:false}'; }
health_git checkout -q -- app.ts
expect 0 "$T" "$(turn_event UserPromptSubmit)" "code-health: turn start records the base"
printf 'export function f(a) {\n  if (a) { if (a.b) { if (a.c) { if (a.d) { return 1; } } } }\n  return 0;\n}\n' >"$health/app.ts"
health_git add -A && health_git commit -q -m regression
expect 2 "$H" "$(turn_event Stop)" "code-health: regression committed during the turn is caught" "x new"
expect 0 "$T" "$(turn_event UserPromptSubmit)" "code-health: next turn starts from the new commit"
expect 0 "$H" "$(turn_event Stop)" "code-health: committed finding is existing in the next turn"
expect 0 "$T" "$(jq -cn --arg d "$health/missing" '{cwd:$d}')" "code-health: turn start fails open"
unset CODE_HEALTH_STATE_DIR

echo
if ((failures)); then
  echo "$failures failure(s)"
  exit 1
fi
echo "all passed"

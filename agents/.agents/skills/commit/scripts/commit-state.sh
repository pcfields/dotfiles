#!/usr/bin/env bash
# Prints what the commit skill needs before planning: the context, any local
# overlay to read, the branch, status, staged and unstaged diff stats, and
# recent commits to match their style.
#
# Context and overlay: see ../../../lib/local-context.sh.
#
# Run: bash commit-state.sh
set -euo pipefail

# -P: the skill may be reached through a symlink in ~/.claude/skills.
source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/lib/local-context.sh"

main() {
  local context
  read -r context _ <<<"$(local_context)"
  echo "context: $context"
  print_overlay commit "$context"
  echo "branch: $(git branch --show-current)"
  section "Status" git status --short
  section "Staged" git diff --cached --stat
  section "Unstaged" git diff --stat
  section "Recent commits" git log --oneline -10
}

# section <title> <command...>: prints the command's output, or "(none)".
section() {
  local title="$1" output
  shift
  output="$("$@")"
  printf '\n## %s\n%s\n' "$title" "${output:-(none)}"
}

main "$@"

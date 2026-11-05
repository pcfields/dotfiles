#!/usr/bin/env bash
# Prints what the commit skill needs before planning: status, staged and
# unstaged diff stats, and recent commits to match their style.
# Run: bash commit-state.sh
set -euo pipefail

main() {
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

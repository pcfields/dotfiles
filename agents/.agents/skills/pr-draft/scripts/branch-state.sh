#!/usr/bin/env bash
# Prints what pr-draft needs about the current branch: its context, the base
# it merges into, any local overlay to read, its commits, changed files and
# any uncommitted work.
#
# Context and overlay: see ../../../lib/local-context.sh.
#
# Run: bash branch-state.sh [base]    (an explicit base overrides detection)
set -euo pipefail

# -P: the skill may be reached through a symlink in ~/.claude/skills.
source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/lib/local-context.sh"

main() {
  local context context_base base
  read -r context context_base <<<"$(local_context)"
  base="${1:-${context_base:-$(default_base)}}"

  if ! git rev-parse --verify --quiet "$base^{commit}" >/dev/null; then
    echo "error: base '$base' not found; fetch it or pass a base explicitly" >&2
    exit 1
  fi

  echo "context: $context"
  echo "base: $base"
  print_overlay pr-draft "$context"
  echo "branch: $(git branch --show-current)"
  section "Commits ($base..HEAD)" git log --oneline --first-parent "$base..HEAD"
  section "Files changed" git diff --stat "$base...HEAD"
  section "Uncommitted" git status --short
}

default_base() {
  if git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null; then
    :
  elif git rev-parse --verify --quiet origin/main >/dev/null; then
    echo origin/main
  else
    echo origin/master
  fi
}

# section <title> <command...>: prints the command's output, or "(none)".
section() {
  local title="$1" output
  shift
  output="$("$@")"
  printf '\n## %s\n%s\n' "$title" "${output:-(none)}"
}

main "$@"

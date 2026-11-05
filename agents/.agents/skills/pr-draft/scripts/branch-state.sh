#!/usr/bin/env bash
# Prints what pr-draft needs about the current branch: work or personal
# context, the base it merges into, its commits, changed files and any
# uncommitted work. Work means an Azure DevOps origin, which merges into dev.
# Run: bash branch-state.sh [base]    (an explicit base overrides detection)
set -euo pipefail

main() {
  local origin context base
  origin="$(git remote get-url origin 2>/dev/null || true)"
  context="$(context_for "$origin")"
  base="${1:-$(default_base "$context")}"

  if ! git rev-parse --verify --quiet "$base^{commit}" >/dev/null; then
    echo "error: base '$base' not found; fetch it or pass a base explicitly" >&2
    exit 1
  fi

  echo "context: $context"
  echo "base: $base"
  echo "branch: $(git branch --show-current)"
  section "Commits ($base..HEAD)" git log --oneline --first-parent "$base..HEAD"
  section "Files changed" git diff --stat "$base...HEAD"
  section "Uncommitted" git status --short
}

# context_for <origin url>: work for Azure DevOps (both URL styles), else personal.
context_for() {
  case "$1" in
    *dev.azure.com[:/]* | *visualstudio.com[:/]*) echo work ;;
    *) echo personal ;;
  esac
}

default_base() {
  if [[ "$1" == work ]]; then
    echo origin/dev
  elif git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null; then
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

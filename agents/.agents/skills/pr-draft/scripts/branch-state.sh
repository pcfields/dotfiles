#!/usr/bin/env bash
# Prints what pr-draft needs about the current branch: its context, the base
# it merges into, any local overlay to read, its commits, changed files and
# any uncommitted work.
#
# Contexts and overlays come from a folder outside this repo, so nothing
# about an employer or client is published (AGENTS_LOCAL_DIR overrides it):
#
#   ~/.agents-local/contexts.txt                    <pattern> <context> [<base>]
#   ~/.agents-local/overlays/pr-draft/<context>.md  extra rules for that context
#
# The first contexts.txt line whose pattern occurs in the origin URL names the
# context and, optionally, the branch its PRs merge into. Without the folder
# or a match the context is `default`.
#
# Run: bash branch-state.sh [base]    (an explicit base overrides detection)
set -euo pipefail

LOCAL_DIR="${AGENTS_LOCAL_DIR:-$HOME/.agents-local}"

main() {
  local origin context context_base base overlay
  origin="$(git remote get-url origin 2>/dev/null || true)"
  read -r context context_base <<<"$(context_for "$origin")"
  base="${1:-${context_base:-$(default_base)}}"

  if ! git rev-parse --verify --quiet "$base^{commit}" >/dev/null; then
    echo "error: base '$base' not found; fetch it or pass a base explicitly" >&2
    exit 1
  fi

  echo "context: $context"
  echo "base: $base"
  overlay="$LOCAL_DIR/overlays/pr-draft/$context.md"
  if [[ -f "$overlay" ]]; then echo "overlay: $overlay"; fi
  echo "branch: $(git branch --show-current)"
  section "Commits ($base..HEAD)" git log --oneline --first-parent "$base..HEAD"
  section "Files changed" git diff --stat "$base...HEAD"
  section "Uncommitted" git status --short
}

# context_for <origin url>: prints "<context> [<base>]" from the first
# contexts.txt line whose pattern occurs in the URL, else "default".
context_for() {
  local file="$LOCAL_DIR/contexts.txt" pattern context base
  if [[ -n "$1" && -f "$file" ]]; then
    while read -r pattern context base; do
      [[ -n "$context" && "$pattern" != \#* ]] || continue
      if [[ "$1" == *"$pattern"* ]]; then
        echo "$context $base"
        return
      fi
    done < <(tr -d '\r' <"$file"; echo)
  fi
  echo default
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

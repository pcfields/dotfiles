#!/usr/bin/env bash
# Runs the current project's `check` command, if it has one, when there are
# uncommitted changes. Knows nothing about any agent harness: a harness
# adapter, a git hook or a person can call it.
#
# Exit 0: the check passed, or there was nothing to run.
# Exit 2: the check failed; the reason is on stderr.
#
# Run: bash run-project-check.sh [<dir>]    (CHECK_TIMEOUT=<seconds>, default 120)
set -euo pipefail

# Lines of the check's output to show on failure.
OUTPUT_TAIL=60

main() {
  local dir="${1:-.}" root
  root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || exit 0
  cd "$root"

  # Nothing edited since the last commit: nothing new to check.
  [[ -n "$(git status --porcelain)" ]] || exit 0

  local check=()
  find_check
  ((${#check[@]})) || exit 0

  run_check "${CHECK_TIMEOUT:-120}" "${check[@]}"
}

# find_check: sets `check` to the project's check command, or leaves it empty.
# The first source that defines `check` wins.
find_check() {
  if [[ -f .agents/check ]]; then
    check=(bash .agents/check)
  elif has_package_script; then
    check=("$(package_manager)" run check)
  elif has_just_recipe; then
    check=(just check)
  elif has_make_target; then
    check=(make check)
  elif has_mise_task; then
    check=(mise run check)
  fi
}

has_package_script() {
  [[ -f package.json ]] && command -v jq >/dev/null &&
    jq -e '.scripts.check // empty' package.json >/dev/null 2>&1
}

# package_manager: the one the lockfile belongs to; npm when there is none.
package_manager() {
  if [[ -f pnpm-lock.yaml ]]; then
    echo pnpm
  elif [[ -f yarn.lock ]]; then
    echo yarn
  elif [[ -f bun.lock || -f bun.lockb ]]; then
    echo bun
  else
    echo npm
  fi
}

has_just_recipe() {
  [[ -f justfile || -f Justfile || -f .justfile ]] && command -v just >/dev/null &&
    just --summary 2>/dev/null | tr ' ' '\n' | grep -qx check
}

has_make_target() {
  local file
  command -v make >/dev/null || return 1
  for file in GNUmakefile makefile Makefile; do
    [[ -f "$file" ]] && grep -qE '^check[[:space:]]*:' "$file" && return 0
  done
  return 1
}

# mise lists no tasks for a config the user hasn't trusted, so an untrusted
# project is skipped here rather than run.
has_mise_task() {
  [[ -f mise.toml || -f .mise.toml ]] && command -v mise >/dev/null &&
    mise tasks ls 2>/dev/null | awk '{ print $1 }' | grep -qx check
}

# run_check <timeout-seconds> <command...>
run_check() {
  local limit="$1" output status=0
  shift
  output="$(mktemp)"
  trap "rm -f '$output'" EXIT

  if command -v timeout >/dev/null; then
    timeout "$limit" "$@" >"$output" 2>&1 || status=$?
  else
    "$@" >"$output" 2>&1 || status=$?
  fi

  ((status == 0)) && exit 0

  # A check that hangs is the project's problem, not grounds to block.
  if ((status == 124)); then
    echo "Project check timed out after ${limit}s and was skipped: $*" >&2
    exit 0
  fi

  {
    echo "Project check failed (exit $status): $*"
    echo
    tail -n "$OUTPUT_TAIL" "$output"
    echo
    echo "Fix what your changes broke and run the check again. If a failure"
    echo "was there before your changes, or you can't fix it, leave it and"
    echo "tell the user."
  } >&2
  exit 2
}

main "$@"

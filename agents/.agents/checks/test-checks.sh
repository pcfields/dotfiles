#!/usr/bin/env bash
# Regression fixtures for run-project-check.sh. Each case builds a throwaway
# git repo and checks the exit code. Run: bash test-checks.sh
set -euo pipefail

CHECK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/run-project-check.sh"
WORK="$(mktemp -d)"
trap "rm -rf '$WORK'" EXIT
failures=0

# new_repo <name>: an empty committed repo; prints its path.
new_repo() {
  local dir="$WORK/$1"
  mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false \
    commit -q --allow-empty -m init
  echo "$dir"
}

# expect <want-exit> <dir> <label> [<text expected on stderr>]
expect() {
  local want="$1" dir="$2" label="$3" text="${4:-}" got=0 stderr
  stderr="$(bash "$CHECK" "$dir" 2>&1 >/dev/null)" || got=$?
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

mkdir -p "$WORK/plain"
expect 0 "$WORK/plain" "not a git repo"

repo="$(new_repo clean)"
mkdir "$repo/.agents" && echo 'exit 1' >"$repo/.agents/check"
git -C "$repo" add -A
git -C "$repo" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false commit -q -m check
expect 0 "$repo" "clean working tree skips a failing check"

repo="$(new_repo nocheck)"
echo x >"$repo/file"
expect 0 "$repo" "changes but no check command"

repo="$(new_repo passing)"
mkdir "$repo/.agents" && echo 'echo fine' >"$repo/.agents/check"
expect 0 "$repo" ".agents/check passes"

repo="$(new_repo failing)"
mkdir "$repo/.agents" && printf 'echo "lint: unused variable"\nexit 3\n' >"$repo/.agents/check"
expect 2 "$repo" ".agents/check fails" "lint: unused variable"

repo="$(new_repo subdir)"
mkdir -p "$repo/.agents" "$repo/src/deep" && echo 'exit 1' >"$repo/.agents/check"
expect 2 "$repo/src/deep" "run from a subdirectory finds the repo root"

repo="$(new_repo make)"
printf 'check:\n\t@echo "types: error"; exit 1\n' >"$repo/Makefile"
expect 2 "$repo" "Makefile check target fails" "types: error"

repo="$(new_repo makeother)"
printf 'build:\n\t@exit 1\n' >"$repo/Makefile"
expect 0 "$repo" "Makefile without a check target"

repo="$(new_repo precedence)"
mkdir "$repo/.agents" && echo 'exit 0' >"$repo/.agents/check"
printf 'check:\n\t@exit 1\n' >"$repo/Makefile"
expect 0 "$repo" ".agents/check wins over the Makefile"

if command -v npm >/dev/null && command -v jq >/dev/null; then
  repo="$(new_repo npm)"
  echo '{"scripts":{"check":"echo pkg-check-failed && exit 1"}}' >"$repo/package.json"
  expect 2 "$repo" "package.json check script fails" "pkg-check-failed"

  repo="$(new_repo npmother)"
  echo '{"scripts":{"lint":"exit 1"},"dependencies":{"check":"1.0.0"}}' >"$repo/package.json"
  expect 0 "$repo" "package.json with no check script"
else
  printf 'skip  package.json cases (npm or jq missing)\n'
fi

if command -v timeout >/dev/null; then
  repo="$(new_repo slow)"
  mkdir "$repo/.agents" && echo 'sleep 5' >"$repo/.agents/check"
  CHECK_TIMEOUT=1 expect 0 "$repo" "a check that times out does not block" "timed out"
else
  printf 'skip  timeout case (timeout missing)\n'
fi

if ((failures)); then
  printf '\n%d failed\n' "$failures"
  exit 1
fi
printf '\nall passed\n'

#!/usr/bin/env bash
# Regression fixtures for branch-state.sh. Each case runs it in a throwaway
# repo against a throwaway ~/.agents-local. Run: bash test-branch-state.sh
set -euo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/branch-state.sh"
WORK="$(mktemp -d)"
trap "rm -rf '$WORK'" EXIT
failures=0

# new_repo <name> <origin url>: a committed repo with origin/main and
# origin/dev refs; prints its path.
new_repo() {
  local dir="$WORK/$1"
  mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false \
    commit -q --allow-empty -m init
  git -C "$dir" remote add origin "$2"
  git -C "$dir" update-ref refs/remotes/origin/main HEAD
  git -C "$dir" update-ref refs/remotes/origin/dev HEAD
  echo "$dir"
}

# state <repo> <local dir> [base]: the script's output for that repo.
state() {
  local repo="$1" local_dir="$2"
  shift 2
  (cd "$repo" && AGENTS_LOCAL_DIR="$local_dir" bash "$SCRIPT" "$@" 2>&1) || true
}

# expect_line <output> <line> <label>: the output has exactly that line.
expect_line() {
  if grep -qxF -- "$2" <<<"$1"; then
    printf 'ok    %s\n' "$3"
  else
    printf 'FAIL  %s (no line "%s")\n' "$3" "$2"
    failures=$((failures + 1))
  fi
}

# expect_no <output> <text> <label>: the output doesn't mention the text.
expect_no() {
  if grep -qF -- "$2" <<<"$1"; then
    printf 'FAIL  %s (found "%s")\n' "$3" "$2"
    failures=$((failures + 1))
  else
    printf 'ok    %s\n' "$3"
  fi
}

company="$(new_repo company https://dev.example.com/team/app)"
other="$(new_repo other git@github.com:someone/app.git)"

out="$(state "$company" "$WORK/missing")"
expect_line "$out" "context: default" "no local folder: default context"
expect_line "$out" "base: origin/main" "no local folder: default base"
expect_no "$out" "overlay:" "no local folder: no overlay"

local_dir="$WORK/local"
mkdir -p "$local_dir"
printf '# pattern context base\r\n\ndev.example.com work origin/dev\nexample.org client\n' \
  >"$local_dir/contexts.txt"

out="$(state "$company" "$local_dir")"
expect_line "$out" "context: work" "matching origin: named context"
expect_line "$out" "base: origin/dev" "matching origin: the context's base"
expect_no "$out" "overlay:" "context without an overlay file: no overlay"

mkdir -p "$local_dir/overlays/pr-draft"
echo '# Work PRs' >"$local_dir/overlays/pr-draft/work.md"
out="$(state "$company" "$local_dir")"
expect_line "$out" "overlay: $local_dir/overlays/pr-draft/work.md" "overlay file is listed"

out="$(state "$company" "$local_dir" origin/main)"
expect_line "$out" "base: origin/main" "explicit base wins over the context's"

out="$(state "$other" "$local_dir")"
expect_line "$out" "context: default" "unmatched origin: default context"
expect_line "$out" "base: origin/main" "unmatched origin: default base"
expect_no "$out" "overlay:" "unmatched origin: no overlay"

echo
if ((failures)); then
  echo "$failures failure(s)"
  exit 1
fi
echo "all passed"

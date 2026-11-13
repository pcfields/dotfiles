#!/usr/bin/env bash
# Regression fixtures for commit-state.sh's context and overlay lines. Each
# case runs it in a throwaway repo against a throwaway ~/.agents-local.
# Run: bash test-commit-state.sh
set -euo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commit-state.sh"
WORK="$(mktemp -d)"
trap "rm -rf '$WORK'" EXIT
failures=0

# expect <want: has|lacks> <output> <text> <label>
expect() {
  local found=lacks
  if grep -qF -- "$3" <<<"$2"; then found=has; fi
  if [[ "$found" == "$1" ]]; then
    printf 'ok    %s\n' "$4"
  else
    printf 'FAIL  %s (output %s "%s")\n' "$4" "$found" "$3"
    failures=$((failures + 1))
  fi
}

repo="$WORK/repo"
mkdir -p "$repo"
git -C "$repo" init -q
git -C "$repo" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false \
  commit -q --allow-empty -m init
git -C "$repo" remote add origin https://dev.example.com/team/app

state() { (cd "$repo" && AGENTS_LOCAL_DIR="$1" bash "$SCRIPT" 2>&1) || true; }

out="$(state "$WORK/missing")"
expect has "$out" "context: default" "no local folder: default context"
expect lacks "$out" "overlay:" "no local folder: no overlay"
expect has "$out" "## Recent commits" "still prints the working tree state"

local_dir="$WORK/local"
mkdir -p "$local_dir/overlays/commit"
echo 'dev.example.com work base=origin/dev' >"$local_dir/contexts.txt"
out="$(state "$local_dir")"
expect has "$out" "context: work" "matching origin: named context"
expect lacks "$out" "overlay:" "context without an overlay file: no overlay"

echo '# Work commits' >"$local_dir/overlays/commit/work.md"
out="$(state "$local_dir")"
expect has "$out" "overlay: $local_dir/overlays/commit/work.md" "overlay file is listed"

echo
if ((failures)); then
  echo "$failures failure(s)"
  exit 1
fi
echo "all passed"

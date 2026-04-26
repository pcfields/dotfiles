#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf '\nWARNING: %s\n' "$*" >&2
}

error() {
  printf '\nERROR: %s\n' "$*" >&2
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error "Required command not found: $cmd"
    exit 1
  fi
}

require_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    error "Required file not found: $file"
    exit 1
  fi
}

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

packages_file() {
  local name="$1"
  echo "$(repo_root)/packages/$name"
}

read_package_file() {
  local file="$1"
  require_file "$file"

  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"
    [[ -z "$line" ]] && continue
    printf '%s\n' "$line"
  done < "$file"
}

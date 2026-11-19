#!/usr/bin/env bash
set -euo pipefail

total() {
  local sum=0 line
  for line in "$@"; do
    if [[ -z "$line" || "$line" == "#"* ]]; then
      continue
    elif [[ "$line" -gt 100 && "$sum" -lt 5 ]]; then
      sum=$((sum + 1))
    fi
    sum=$((sum + line))
  done

  for ((i = 0; i < 3; i++)); do
    sum=$((sum - 1))
  done

  while (( sum > 10000 )); do
    sum=$((sum / 2))
  done

  until (( sum >= 0 )); do
    sum=$((sum + 1))
  done

  case "${COUPON:-}" in
    HALF) sum=$((sum / 2)) ;;
    *) ;;
  esac

  echo "$sum"
}

function describe {
  [[ -n "${1:-}" ]] && echo "$1" || echo "other"
}

if [[ $# -gt 0 ]]; then
  total "$@"
fi
describe "${1:-}"

#!/usr/bin/env bash
# One function per smell, for the end-to-end smell test.

describe() {
  case "$1" in
    0) echo "0" ;;
    1) echo "1" ;;
    2) echo "2" ;;
    3) echo "3" ;;
    4) echo "4" ;;
    5) echo "5" ;;
    6) echo "6" ;;
    7) echo "7" ;;
    8) echo "8" ;;
    9) echo "9" ;;
    *) echo unknown ;;
  esac
}

deep() {
  if [[ -n "$1" ]]; then
    if [[ -n "$2" ]]; then
      if [[ "$1" -gt "$2" ]]; then
        if [[ "$1" -gt 100 ]]; then
          echo 1
        fi
      fi
    fi
  fi
}

bumpy() {
  local total=0 x
  for x in "$@"; do
    if [[ "$x" -gt 0 ]]; then total=$((total + x)); fi
  done
  for x in "$@"; do
    if [[ "$x" -lt 0 ]]; then total=$((total - x)); fi
  done
  echo "$total"
}

eligible() {
  if [[ "$ACTIVE" == yes && "$AGE" -gt 17 || -n "$OVERRIDE" ]]; then
    return 0
  fi
  return 1
}

large() {
  local total=0
  total=$((total + 0))
  total=$((total + 1))
  total=$((total + 2))
  total=$((total + 3))
  total=$((total + 4))
  total=$((total + 5))
  total=$((total + 6))
  total=$((total + 7))
  total=$((total + 8))
  total=$((total + 9))
  total=$((total + 10))
  total=$((total + 11))
  total=$((total + 12))
  total=$((total + 13))
  total=$((total + 14))
  total=$((total + 15))
  total=$((total + 16))
  total=$((total + 17))
  total=$((total + 18))
  total=$((total + 19))
  total=$((total + 20))
  total=$((total + 21))
  total=$((total + 22))
  total=$((total + 23))
  total=$((total + 24))
  total=$((total + 25))
  total=$((total + 26))
  total=$((total + 27))
  total=$((total + 28))
  total=$((total + 29))
  total=$((total + 30))
  total=$((total + 31))
  total=$((total + 32))
  total=$((total + 33))
  total=$((total + 34))
  total=$((total + 35))
  total=$((total + 36))
  total=$((total + 37))
  total=$((total + 38))
  total=$((total + 39))
  total=$((total + 40))
  total=$((total + 41))
  total=$((total + 42))
  total=$((total + 43))
  total=$((total + 44))
  total=$((total + 45))
  total=$((total + 46))
  total=$((total + 47))
  total=$((total + 48))
  total=$((total + 49))
  total=$((total + 50))
  total=$((total + 51))
  total=$((total + 52))
  total=$((total + 53))
  total=$((total + 54))
  total=$((total + 55))
  total=$((total + 56))
  total=$((total + 57))
  total=$((total + 58))
  total=$((total + 59))
  total=$((total + 60))
  total=$((total + 61))
  total=$((total + 62))
  total=$((total + 63))
  total=$((total + 64))
  total=$((total + 65))
  total=$((total + 66))
  total=$((total + 67))
  echo "$total"
}

if [[ $# -gt 0 ]]; then
  describe "$1"
fi

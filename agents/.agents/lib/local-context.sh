#!/usr/bin/env bash
# Sourced by skill scripts. Looks up the current repo's context, its settings
# and a skill's overlay in ~/.agents-local (AGENTS_LOCAL_DIR overrides it):
#
#   contexts.txt                   <pattern> <context> [<key>=<value> ...]
#   overlays/<skill>/<context>.md  extra rules for that skill in that context
#
# The first contexts.txt line whose pattern occurs in the origin URL applies.
# Without the folder or a match the context is `default`, with no settings.

AGENTS_LOCAL_DIR="${AGENTS_LOCAL_DIR:-$HOME/.agents-local}"

# local_context: prints the context of the repo in the current directory.
local_context() {
  local context
  read -r context _ <<<"$(context_line)"
  echo "$context"
}

# local_setting <key>: prints the value of that context's <key>=<value>, or
# nothing when it has none.
local_setting() {
  local settings word
  read -r _ settings <<<"$(context_line)"
  for word in $settings; do
    if [[ "$word" == "$1="* ]]; then
      echo "${word#*=}"
      return
    fi
  done
}

# print_overlay <skill>: prints an `overlay: <path>` line when the context has
# extra rules for the skill.
print_overlay() {
  local overlay
  overlay="$AGENTS_LOCAL_DIR/overlays/$1/$(local_context).md"
  if [[ -f "$overlay" ]]; then echo "overlay: $overlay"; fi
}

# context_line: prints "<context> [<key>=<value> ...]" from the matching
# contexts.txt line, else "default".
context_line() {
  local file="$AGENTS_LOCAL_DIR/contexts.txt" origin pattern rest
  origin="$(git remote get-url origin 2>/dev/null || true)"
  if [[ -n "$origin" && -f "$file" ]]; then
    while read -r pattern rest; do
      [[ -n "$rest" && "$pattern" != \#* ]] || continue
      if [[ "$origin" == *"$pattern"* ]]; then
        echo "$rest"
        return
      fi
    done < <(tr -d '\r' <"$file"; echo)
  fi
  echo default
}

#!/usr/bin/env bash
# Sourced by skill scripts. Looks up the current repo's context and a skill's
# overlay in a folder outside this repo, so nothing about an employer or
# client is published (AGENTS_LOCAL_DIR overrides the folder):
#
#   ~/.agents-local/contexts.txt                   <pattern> <context> [<base>]
#   ~/.agents-local/overlays/<skill>/<context>.md  extra rules for that context
#
# The first contexts.txt line whose pattern occurs in the origin URL names the
# context and, optionally, the branch its PRs merge into. Without the folder
# or a match the context is `default`.

AGENTS_LOCAL_DIR="${AGENTS_LOCAL_DIR:-$HOME/.agents-local}"

# local_context: prints "<context> [<base>]" for the repo in the current
# directory.
local_context() {
  local file="$AGENTS_LOCAL_DIR/contexts.txt" origin pattern context base
  origin="$(git remote get-url origin 2>/dev/null || true)"
  if [[ -n "$origin" && -f "$file" ]]; then
    while read -r pattern context base; do
      [[ -n "$context" && "$pattern" != \#* ]] || continue
      if [[ "$origin" == *"$pattern"* ]]; then
        echo "$context $base"
        return
      fi
    done < <(tr -d '\r' <"$file"; echo)
  fi
  echo default
}

# print_overlay <skill> <context>: prints an `overlay: <path>` line when that
# context has extra rules for the skill.
print_overlay() {
  local overlay="$AGENTS_LOCAL_DIR/overlays/$1/$2.md"
  if [[ -f "$overlay" ]]; then echo "overlay: $overlay"; fi
}

#!/usr/bin/env bash
# Verifies the shared agent config and its wiring into each harness.
# Run: ./install/check-agent-config.sh    (AGENTS_DIR overrides the package dir)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS_DIR="${AGENTS_DIR:-$ROOT_DIR/agents/.agents}"
failures=0

# Wiring is checked against the repo, so only compare links when using it.
check_wiring=1
[[ "$AGENTS_DIR" == "$ROOT_DIR/agents/.agents" ]] || check_wiring=0

pass() { printf 'ok    %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; failures=$((failures + 1)); }

# frontmatter_value <file> <key>: first `key: value` between the --- fences.
frontmatter_value() {
  awk -v key="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    index($0, key ":") == 1 { sub("^" key ":[ ]*", ""); print; exit }
  ' "$1"
}

check_skills() {
  local dir name file
  for dir in "$AGENTS_DIR"/skills/*/; do
    dir="${dir%/}"
    name="$(basename "$dir")"
    file="$dir/SKILL.md"
    if [[ ! -f "$file" ]]; then fail "skill $name: SKILL.md missing"; continue; fi
    if [[ "$(frontmatter_value "$file" name)" != "$name" ]]; then
      fail "skill $name: frontmatter name must equal the folder name"
    elif [[ -z "$(frontmatter_value "$file" description)" ]]; then
      fail "skill $name: description missing"
    else
      pass "skill $name"
    fi
  done
}

check_wiring_links() {
  local dir name link

  [[ "$(readlink -f "$HOME/.agents")" == "$(readlink -f "$AGENTS_DIR")" ]] \
    && pass "~/.agents -> package" || fail "~/.agents does not point at $AGENTS_DIR (run ./install.sh stow)"

  for dir in "$AGENTS_DIR"/skills/*/; do
    name="$(basename "$dir")"
    link="$HOME/.claude/skills/$name"
    [[ "$(readlink -f "$link")" == "$(readlink -f "$dir")" ]] \
      && pass "claude skill $name linked" || fail "~/.claude/skills/$name not linked (run ./install.sh agent-links)"
  done

  for link in "$HOME"/.claude/skills/*; do
    [[ -L "$link" && ! -e "$link" ]] && fail "dangling skill link: $link"
  done

  [[ "$(readlink -f "$HOME/.codex/AGENTS.md")" == "$(readlink -f "$AGENTS_DIR/AGENTS.md")" ]] \
    && pass "codex AGENTS.md linked" || fail "~/.codex/AGENTS.md not linked (run ./install.sh agent-links)"

  grep -q '^@~/.agents/AGENTS.md$' "$ROOT_DIR/claude/.claude/CLAUDE.md" \
    && pass "CLAUDE.md imports shared file" || fail "CLAUDE.md is missing @~/.agents/AGENTS.md"

  jq -e '.instructions // [] | index("~/.agents/AGENTS.md")' "$ROOT_DIR/opencode/.config/opencode/opencode.json" >/dev/null \
    && pass "opencode.json loads shared file" || fail "opencode.json instructions missing ~/.agents/AGENTS.md"
}

[[ -f "$AGENTS_DIR/AGENTS.md" ]] && pass "AGENTS.md present" || fail "AGENTS.md missing"
check_skills
(( check_wiring )) && check_wiring_links

if (( failures )); then printf '\n%d check(s) failed\n' "$failures"; exit 1; fi
printf '\nall passed\n'
